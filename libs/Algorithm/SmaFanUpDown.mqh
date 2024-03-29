
#include <Trade\PositionInfo.mqh>
#include <trade/trade.mqh>
#include  "..\ExpertWrapper.mqh"
#include  "..\Common.mqh"
#include  "IAlgorithm.mqh"
#resource "\\Indicators\\ForexProEA_6_4_Fan.ex5"


// ===================================================================
// Tham số đầu vào [start]
// ===================================================================
input double InpSmaFanLotFix = 0.01;
input double InpSmaFanLotPercent = 0;
input int   InpSmaFanMinSL = 300;
input int   InpSmaFanMaxSL = 400;
input int   InpSmaFanSLBuff = 30; // Một khoảng cách phụ thêm cho SL
input double   InpSmaFanTpRatio = 1;  // Tỉ lệ TP so với SL
input bool  InpSmaFanLimitTradeTime = false;     // Chỉ định thời gian giao dịch?
input uint   InpSmaFanLimitTradeTimeStart = 13;  // |- Thời gian giao dịch >= Giờ bắt đầu
input uint   InpSmaFanLimitTradeTimeEnd = 23;    // |- Thời gian giao dịch < Giở kết thúc

#include  "..\Hedge.mqh"
input group "Thiết lập chiến thuật ""double in a day"""
input bool   InpUseDoubleInDay = false;                 // Sử dụng chiến thuật topup
input int    InpDoubleInDayTopupOrders = 3;             // Số lệnh topup
input string InpDoubleInDayLotsRatioChain = "1.73;3.18;6";    // Tỉ lệ lot của top cách bằng dấu ";"
input string InpDoubleInDayDistanceRatioChain = "2.5;4.5;5.5"; // Tỉ lệ khoảng cách so với init
input double InpDoubleInDayTpRatioVsSLFromLastTopup = 2.1;  // Tỉ lệ TP so với SL tính từ order cuối
#include  "..\DoubleInDay.mqh"
// ===================================================================
// Tham số đầu vào [end]
// ===================================================================

// ===================================================================
// Class xử lý giao dịch theo mô hình EMA tỏa ra, thừa kế IAlgorithm
// ===================================================================
class CSmaFanUpDown: public IAlgorithm
{
    private:
        double m_lot;
        double m_signalBuffer[], 
               m_sma8Buffer[], m_sma7Buffer[], m_sma6Buffer[],
               m_sma5Buffer[], m_sma4Buffer[], m_sma3Buffer[],
               m_sma2Buffer[], m_sma1Buffer[],
               m_atrBuffer[], m_rsiBuffer[], m_volBuffer[],
               m_adxBuffer[], m_adxPlusBuffer[], m_adxMinusBuffer[];
        int m_fanHandler, m_atrHandler, m_rsiHandler, m_volHandler, m_adxHandler;
        CHedge *m_hedge;
        CDoubleInDay *m_doubleInDay;
        datetime m_lastTimeOps;
    public:
        void Vol(double vol)
        {
            m_lot = vol;
        }
        int Init(string symbol, ENUM_TIMEFRAMES tf, 
                       CTrade &trader, AllSeriesInfo &infoCurrency,
                       string prefixComment, int magicNumber)
        {
            IAlgorithm::Init(symbol, tf, trader, infoCurrency, prefixComment, magicNumber);
            
            InitSeries(m_sma1Buffer);
            InitSeries(m_sma2Buffer);
            InitSeries(m_sma3Buffer);
            InitSeries(m_sma4Buffer);
            InitSeries(m_sma5Buffer);
            InitSeries(m_sma6Buffer);
            InitSeries(m_sma7Buffer);
            InitSeries(m_sma8Buffer);
            InitSeries(m_signalBuffer);
            
            //ArraySetAsSeries(m_signalBuffer, true);
            //ArraySetAsSeries(m_sma7Buffer, true);
            //ArraySetAsSeries(m_sma8Buffer, true);
            m_fanHandler = iCustom(m_symbolCurrency, m_tf, 
                                    "::Indicators\\ForexProEA_6_4_Fan", 
                                    4,8,12,16,20,24,28,50);
            m_lot = InpSmaFanLotFix;
            
            string lots[];
            // Khởi tạo đối tượng hedge
            if(InpUseHedge)
            {
                m_hedge = new CHedge();
                m_hedge.InitHedge(m_symbolCurrency, m_tf, m_trader, m_infoCurrency, m_magicNumber);
                m_hedge.MaxWireHedge(InpHedgeMaxWire);
                m_hedge.RR(InpHedgeRiskReward);
                m_hedge.LotChain(InpHedgeLotsChain);
                m_hedge.ExpectProfit(InpHedgeExpectProfit);
                m_hedge.SetAppendComment(m_prefixComment);
                m_hedge.InternalComment("hedge");
                Split(InpHedgeLotsChain, ";", lots);
                m_lot = (double)lots[0];
            }
            
            if(InpUseDoubleInDay)
            {
                m_doubleInDay = new CDoubleInDay();
                m_doubleInDay.Init(m_symbolCurrency, m_tf, m_trader, m_infoCurrency, m_magicNumber);
                m_doubleInDay.LotRatioChain(InpDoubleInDayLotsRatioChain);
                m_doubleInDay.SetAppendComment(m_prefixComment);
                m_doubleInDay.Topup(InpDoubleInDayTopupOrders);
                m_doubleInDay.DistancesRatio(InpDoubleInDayDistanceRatioChain);
                m_doubleInDay.TpRatioFromLastTopup(InpDoubleInDayTpRatioVsSLFromLastTopup);
                m_doubleInDay.InternalComment("x2");
            }
            
            InitSeries(m_rsiBuffer);
            m_rsiHandler = iRSI(m_symbolCurrency, m_tf, 14, PRICE_CLOSE);
            
            InitSeries(m_volBuffer);
            m_volHandler = iVolumes(m_symbolCurrency, m_tf, VOLUME_TICK);
            
            InitSeries(m_adxBuffer);
            InitSeries(m_adxPlusBuffer);
            InitSeries(m_adxMinusBuffer);
            m_adxHandler = iADXWilder(m_symbolCurrency, m_tf, 14);
            
            //ArraySetAsSeries(m_atrBuffer, true);
            //m_atrHandler = 
            //iATR(m_symbolCurrency, m_tf, 14);
            
            return INIT_SUCCEEDED;
        }
        
        // =======================================================
        void Process(int limit)
        {
            // Gọi xử lý của đối tượng hedge
            if(InpUseHedge)
            {
                if(m_hedge.ExistWire())
                    if(m_doubleInDay != NULL)
                        m_doubleInDay.Disable(true);
                m_hedge.Process(limit);
            }
            if(InpUseDoubleInDay)
            {
                if(m_doubleInDay.ExistTopup())
                    if(m_hedge != NULL)
                        m_hedge.Disable(true);
                m_doubleInDay.Process(limit);
                
            }
            if(limit <= 0)
                return;
            
            m_infoCurrency.refresh();
            
            
            //int atrBars = Bars(m_symbolCurrency, PERIOD_H4);
            //CopyBuffer(m_atrHandler, 0, 0, atrBars, m_atrBuffer);
                        
            MoveSLToEntryByProfitVsSL(m_symbolCurrency, m_magicNumber, 1, m_trader, 5, true, true, m_prefixComment);
            
            if(InpSmaFanLimitTradeTime)
            {
                MqlDateTime currTime;
                TimeToStruct(TimeCurrent(), currTime);
                if(currTime.hour < (int)InpSmaFanLimitTradeTimeStart 
                   || currTime.hour >= (int)InpSmaFanLimitTradeTimeEnd)
                    return;
            }
            
            int bars = Bars(m_symbolCurrency, m_tf);
            CopyBuffer(m_fanHandler, 0, 0, bars, m_sma1Buffer);
            CopyBuffer(m_fanHandler, 1, 0, bars, m_sma2Buffer);
            CopyBuffer(m_fanHandler, 2, 0, bars, m_sma3Buffer);
            CopyBuffer(m_fanHandler, 3, 0, bars, m_sma4Buffer);
            CopyBuffer(m_fanHandler, 4, 0, bars, m_sma5Buffer);
            CopyBuffer(m_fanHandler, 5, 0, bars, m_sma6Buffer);
            CopyBuffer(m_fanHandler, 6, 0, bars, m_sma7Buffer);
            CopyBuffer(m_fanHandler, 7, 0, bars, m_sma8Buffer);
            CopyBuffer(m_fanHandler, 8, 0, bars, m_signalBuffer);
            
            CopyBuffer(m_rsiHandler, 0, 0, bars, m_rsiBuffer);
            CopyBuffer(m_volHandler, 0, 0, bars, m_volBuffer);
            
            CopyBuffer(m_adxHandler, 0, 0, bars, m_adxBuffer);
            CopyBuffer(m_adxHandler, 1, 0, bars, m_adxPlusBuffer);
            CopyBuffer(m_adxHandler, 2, 0, bars, m_adxMinusBuffer);
            
            
            int openPos = GetActivePositions(m_symbolCurrency, m_magicNumber, true, true, m_prefixComment);
            int pendingOrder = GetPendingOrdersByType(m_symbolCurrency, m_magicNumber, ORDER_TYPE_BUY_LIMIT, m_prefixComment + ";01")
                               + GetPendingOrdersByType(m_symbolCurrency, m_magicNumber, ORDER_TYPE_SELL_LIMIT, m_prefixComment + ";01")
                               + GetPendingOrdersByType(m_symbolCurrency, m_magicNumber, ORDER_TYPE_SELL_STOP, m_prefixComment + ";01")
                               + GetPendingOrdersByType(m_symbolCurrency, m_magicNumber, ORDER_TYPE_BUY_STOP, m_prefixComment + ";01");
            if(pendingOrder > 0)
            {
                if(IsSellSignal(1) || IsBuySignal(1))
                {
                    if(IsLastTimeOpsDiffNow())
                    {
                        ClosePendingOrders(m_trader, m_symbolCurrency, m_magicNumber, ORDER_TYPE_SELL_STOP, m_prefixComment + ";01");
                        ClosePendingOrders(m_trader, m_symbolCurrency, m_magicNumber, ORDER_TYPE_BUY_STOP, m_prefixComment + ";01");
                        ClosePendingOrders(m_trader, m_symbolCurrency, m_magicNumber, ORDER_TYPE_BUY_LIMIT, m_prefixComment + ";01");
                        ClosePendingOrders(m_trader, m_symbolCurrency, m_magicNumber, ORDER_TYPE_SELL_LIMIT, m_prefixComment + ";01");
                        pendingOrder = 0;
                    }
                }
                if(m_infoCurrency.close(1) < m_sma7Buffer[1])
                    ClosePendingOrders(m_trader, m_symbolCurrency, m_magicNumber, ORDER_TYPE_BUY_LIMIT, m_prefixComment);
                if(m_infoCurrency.close(1) > m_sma7Buffer[1])
                    ClosePendingOrders(m_trader, m_symbolCurrency, m_magicNumber, ORDER_TYPE_SELL_LIMIT, m_prefixComment);
                
            }
            
            if(openPos == 0 && pendingOrder == 0)
            {
                
                ProcessBuy(limit);
                ProcessSell(limit);
            }
        }
        void ProcessBuy(int limit)
        {
            bool now = false;
            if(CanBuy(1, now))
            {
                double priceBuff = PointsToPriceShift(m_symbolCurrency, InpSmaFanSLBuff);
                if(now)
                {
                    double entry = m_infoCurrency.ask();
                    double sl = (m_signalBuffer[1] + entry) / 2;
                    //double sl = m_signalBuffer[1] - priceBuff;
                    
                    int slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - sl));
                    if(slPoints < InpSmaFanMinSL)
                        slPoints = InpSmaFanMinSL;
                    if(slPoints > InpSmaFanMaxSL)
                        slPoints = InpSmaFanMaxSL;
                    sl = entry - PointsToPriceShift(m_symbolCurrency, slPoints);
                    double tp = entry + MathAbs(entry - sl) * InpSmaFanTpRatio;
                    int tpPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - tp));
                    string comment = m_prefixComment + ";01;" + (string)slPoints + ";" + (string)tpPoints;
                    if(InpSmaFanLotPercent > 0)
                        m_lot = PointsToLots(m_symbolCurrency, InpSmaFanLotPercent, slPoints);
                    m_trader.Buy(m_lot, m_symbolCurrency, 0, sl, tp, comment);
                    
                    if(m_doubleInDay != NULL)
                        m_doubleInDay.Disable(false);
                    if(m_hedge != NULL)
                        m_hedge.Disable(false);
                }
                else
                {
                    //double entry = m_sma2Buffer[1];
                    double entry = m_signalBuffer[1];
                    double sl = m_signalBuffer[1] - priceBuff;
                    
                    int slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - sl));
                    if(slPoints < InpSmaFanMinSL)
                        slPoints = InpSmaFanMinSL;
                    if(slPoints > InpSmaFanMaxSL)
                        slPoints = InpSmaFanMaxSL;
                    sl = entry - PointsToPriceShift(m_symbolCurrency, slPoints);
                    double tp = entry + MathAbs(entry - sl) * InpSmaFanTpRatio;
                    int tpPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - tp));
                    string comment = m_prefixComment + ";01;" + (string)slPoints + ";" + (string)tpPoints;
                    if(InpSmaFanLotPercent > 0)
                        m_lot = PointsToLots(m_symbolCurrency, InpSmaFanLotPercent, slPoints);
                    m_trader.BuyLimit(m_lot, entry, m_symbolCurrency, sl, tp, 0, 0, comment);
                    
                    if(m_doubleInDay != NULL)
                        m_doubleInDay.Disable(false);
                    if(m_hedge != NULL)
                        m_hedge.Disable(false);
                }
                m_lastTimeOps = TimeCurrent();
            }
        }
        
        void ProcessSell(int limit)
        {
            bool now = false;
            if(CanSell(1, now))
            {
                double priceBuff = PointsToPriceShift(m_symbolCurrency, InpSmaFanSLBuff);
                if(now)
                {
                    double entry = m_infoCurrency.bid();
                    double sl = (m_signalBuffer[1] + entry) / 2;
                    //double sl = m_signalBuffer[1] + priceBuff;
                    
                    int slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - sl));
                    if(slPoints < InpSmaFanMinSL)
                        slPoints = InpSmaFanMinSL;
                    if(slPoints > InpSmaFanMaxSL)
                        slPoints = InpSmaFanMaxSL;
                    sl = entry + PointsToPriceShift(m_symbolCurrency, slPoints);
                    double tp = entry - MathAbs(entry - sl) * InpSmaFanTpRatio;
                    int tpPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - tp));
                    string comment = m_prefixComment + ";01;" + (string)slPoints + ";" + (string)tpPoints;
                    if(InpSmaFanLotPercent > 0)
                        m_lot = PointsToLots(m_symbolCurrency, InpSmaFanLotPercent, slPoints);
                    m_trader.Sell(m_lot, m_symbolCurrency, 0, sl, tp, comment);
                    
                    if(m_doubleInDay != NULL)
                        m_doubleInDay.Disable(false);
                    if(m_hedge != NULL)
                        m_hedge.Disable(false);
                }
                else
                {
                    //double entry = m_sma2Buffer[1];
                    double entry = m_signalBuffer[1];
                    double sl = m_signalBuffer[1] + priceBuff;
                    
                    int slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - sl));
                    if(slPoints < InpSmaFanMinSL)
                        slPoints = InpSmaFanMinSL;
                    if(slPoints > InpSmaFanMaxSL)
                        slPoints = InpSmaFanMaxSL;
                    sl = entry + PointsToPriceShift(m_symbolCurrency, slPoints);
                    double tp = entry - MathAbs(entry - sl) * InpSmaFanTpRatio;
                    int tpPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - tp));
                    string comment = m_prefixComment + ";01;" + (string)slPoints + ";" + (string)tpPoints;
                    if(InpSmaFanLotPercent > 0)
                        m_lot = PointsToLots(m_symbolCurrency, InpSmaFanLotPercent, slPoints);
                    m_trader.SellLimit(m_lot, entry, m_symbolCurrency, sl, tp, 0, 0, comment);
                    
                    if(m_doubleInDay != NULL)
                        m_doubleInDay.Disable(false);
                    if(m_hedge != NULL)
                        m_hedge.Disable(false);
                }
                m_lastTimeOps = TimeCurrent();
            }
        }
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        bool CanSell(int idx, bool &now)
        {
            now = false;
            
            // =====================================================
            if(   m_infoCurrency.high(1) > m_sma1Buffer[1]
               && m_infoCurrency.high(1) > m_sma2Buffer[1]
               && m_infoCurrency.high(1) > m_sma3Buffer[1]
               && m_infoCurrency.high(1) > m_sma4Buffer[1]
               && m_infoCurrency.high(1) > m_sma5Buffer[1]
               && m_infoCurrency.high(1) > m_sma6Buffer[1]
               && m_infoCurrency.high(1) > m_sma7Buffer[1]
               && m_infoCurrency.high(1) > m_sma8Buffer[1]
               
               && m_infoCurrency.low(1) < m_sma1Buffer[1]
               && m_infoCurrency.low(1) < m_sma2Buffer[1]
               && m_infoCurrency.low(1) < m_sma3Buffer[1]
               && m_infoCurrency.low(1) < m_sma4Buffer[1]
               && m_infoCurrency.low(1) < m_sma5Buffer[1]
               && m_infoCurrency.low(1) < m_sma6Buffer[1]
               && m_infoCurrency.low(1) < m_sma7Buffer[1]
               && m_infoCurrency.low(1) < m_sma8Buffer[1]
               )
            {
                if(IsCandleDown(1, m_infoCurrency))
                {
                    now = true;
                    return true;
                }
            }
            return false;
            
            // =====================================================
            bool isAllOK = true;
            for(int i = 0; i < 5; i++)
            {
                if(!(m_sma1Buffer[i + idx] < m_sma2Buffer[i + idx]
                   && m_sma2Buffer[i + idx] < m_sma3Buffer[i + idx]
                   && m_sma3Buffer[i + idx] < m_sma4Buffer[i + idx]
                   && m_sma4Buffer[i + idx] < m_sma5Buffer[i + idx]
                   && m_sma5Buffer[i + idx] < m_sma6Buffer[i + idx]
                   && m_sma6Buffer[i + idx] < m_sma7Buffer[i + idx]
                   && m_sma7Buffer[i + idx] < m_sma8Buffer[i + idx]))
                    isAllOK = false;
            }
            if(isAllOK)
            {
                if(!(m_sma1Buffer[idx + 5] < m_sma2Buffer[idx + 5]
                   && m_sma2Buffer[idx + 5] < m_sma3Buffer[idx + 5]
                   && m_sma3Buffer[idx + 5] < m_sma4Buffer[idx + 5]
                   && m_sma4Buffer[idx + 5] < m_sma5Buffer[idx + 5]
                   && m_sma5Buffer[idx + 5] < m_sma6Buffer[idx + 5]
                   && m_sma6Buffer[idx + 5] < m_sma7Buffer[idx + 5]
                   && m_sma7Buffer[idx + 5] < m_sma8Buffer[idx + 5]))
                    if(//m_adxBuffer[idx] > 30 && 
                    m_rsiBuffer[idx] < 30)
                    {
                        now = true;
                        return true;
                    }
            }
            return false;
            // =======================================================
            
            if(IsSellSignal(idx) && m_infoCurrency.high(idx) < m_sma2Buffer[idx])
            {
                if(m_rsiBuffer[idx] < 30 
                   && (m_adxBuffer[idx] > 30 || m_adxMinusBuffer[idx] > 30))
                    now = true;
                for(int i = idx + 1; i <= idx + 6; i++)
                {
                    if(m_signalBuffer[i] > 0)
                        now = true;
                }
                
                if(m_rsiBuffer[idx] < 30
                   && (m_sma7Buffer[idx + 1] >= m_sma8Buffer[idx + 1]
                       || m_sma7Buffer[idx + 2] >= m_sma8Buffer[idx + 2]
                       || m_sma7Buffer[idx + 3] >= m_sma8Buffer[idx + 3]
                       || m_sma7Buffer[idx + 4] >= m_sma8Buffer[idx + 4]
                       || m_sma7Buffer[idx + 5] >= m_sma8Buffer[idx + 5])
                   )
                   now = true;
                return true;
                
//                //if(m_sma6Buffer[idx + 1] >= m_sma7Buffer[idx + 1] ||
//                //   m_sma6Buffer[idx + 2] >= m_sma7Buffer[idx + 2] ||
//                //   m_sma6Buffer[idx + 3] >= m_sma7Buffer[idx + 3])
//                if(m_sma7Buffer[idx + 1] >= m_sma8Buffer[idx + 1] ||
//                   m_sma7Buffer[idx + 2] >= m_sma8Buffer[idx + 2] ||
//                   m_sma7Buffer[idx + 3] >= m_sma8Buffer[idx + 3] ||
//                   m_sma6Buffer[idx + 1] >= m_sma7Buffer[idx + 1] ||
//                   m_sma6Buffer[idx + 2] >= m_sma7Buffer[idx + 2] ||
//                   m_sma6Buffer[idx + 3] >= m_sma7Buffer[idx + 3])
//                
//                {
//                    if(m_rsiBuffer[idx] < 20) 
//                       //&& m_rsiBuffer[idx + 1] > 30
//                       //&& m_rsiBuffer[idx + 2] > 30)
//                    {
//                        //if(m_volBuffer[idx] > m_volBuffer[idx + 1])
//                            now = true;
//                    }
//                    return true;
//                }
            }
            return false;
        }
        
        bool CanBuy(int idx, bool &now)
        {
            now = false;
            
            // =====================================================
            if(   m_infoCurrency.high(1) > m_sma1Buffer[1]
               && m_infoCurrency.high(1) > m_sma2Buffer[1]
               && m_infoCurrency.high(1) > m_sma3Buffer[1]
               && m_infoCurrency.high(1) > m_sma4Buffer[1]
               && m_infoCurrency.high(1) > m_sma5Buffer[1]
               && m_infoCurrency.high(1) > m_sma6Buffer[1]
               && m_infoCurrency.high(1) > m_sma7Buffer[1]
               && m_infoCurrency.high(1) > m_sma8Buffer[1]
               
               && m_infoCurrency.low(1) < m_sma1Buffer[1]
               && m_infoCurrency.low(1) < m_sma2Buffer[1]
               && m_infoCurrency.low(1) < m_sma3Buffer[1]
               && m_infoCurrency.low(1) < m_sma4Buffer[1]
               && m_infoCurrency.low(1) < m_sma5Buffer[1]
               && m_infoCurrency.low(1) < m_sma6Buffer[1]
               && m_infoCurrency.low(1) < m_sma7Buffer[1]
               && m_infoCurrency.low(1) < m_sma8Buffer[1]
               )
            {
                if(IsCandleUp(1, m_infoCurrency))
                {
                    now = true;
                    return true;
                }
            }
            return false;
            // =====================================================
            bool isAllOK = true;
            for(int i = 0; i < 5; i++)
            {
                if(!(m_sma1Buffer[i + idx] > m_sma2Buffer[i + idx]
                   && m_sma2Buffer[i + idx] > m_sma3Buffer[i + idx]
                   && m_sma3Buffer[i + idx] > m_sma4Buffer[i + idx]
                   && m_sma4Buffer[i + idx] > m_sma5Buffer[i + idx]
                   && m_sma5Buffer[i + idx] > m_sma6Buffer[i + idx]
                   && m_sma6Buffer[i + idx] > m_sma7Buffer[i + idx]
                   && m_sma7Buffer[i + idx] > m_sma8Buffer[i + idx]))
                    isAllOK = false;
            }
            if(isAllOK)
            {
                if(!(m_sma1Buffer[idx + 5] > m_sma2Buffer[idx + 5]
                   && m_sma2Buffer[idx + 5] > m_sma3Buffer[idx + 5]
                   && m_sma3Buffer[idx + 5] > m_sma4Buffer[idx + 5]
                   && m_sma4Buffer[idx + 5] > m_sma5Buffer[idx + 5]
                   && m_sma5Buffer[idx + 5] > m_sma6Buffer[idx + 5]
                   && m_sma6Buffer[idx + 5] > m_sma7Buffer[idx + 5]
                   && m_sma7Buffer[idx + 5] > m_sma8Buffer[idx + 5]))
                {
                    if(//m_adxBuffer[idx] > 30 && 
                    m_rsiBuffer[idx] > 70)
                    {
                        now = true;
                        return true;
                    }
                }
            }
            return false;
            // =======================================================
            
            
            if(IsBuySignal(idx) && m_infoCurrency.low(idx) > m_sma2Buffer[idx])
            {
                if(m_rsiBuffer[idx] > 70 
                   && (m_adxBuffer[idx] > 30 || m_adxPlusBuffer[idx] > 30))
                    now = true;
                
                for(int i = idx + 1; i <= idx + 6; i++)
                {
                    if(m_signalBuffer[i] > 0)
                        now = true;
                }
                
                if(m_rsiBuffer[idx] > 70
                   && (m_sma7Buffer[idx + 1] <= m_sma8Buffer[idx + 1]
                       || m_sma7Buffer[idx + 2] <= m_sma8Buffer[idx + 2]
                       || m_sma7Buffer[idx + 3] <= m_sma8Buffer[idx + 3]
                       || m_sma7Buffer[idx + 4] <= m_sma8Buffer[idx + 4]
                       || m_sma7Buffer[idx + 5] <= m_sma8Buffer[idx + 5])
                   )
                   now = true;
                   
                return true;
                ////if(m_sma6Buffer[idx + 1] <= m_sma7Buffer[idx + 1] ||
                ////   m_sma6Buffer[idx + 2] <= m_sma7Buffer[idx + 2] ||
                ////   m_sma6Buffer[idx + 3] <= m_sma7Buffer[idx + 3])
                //if(m_sma7Buffer[idx + 1] <= m_sma8Buffer[idx + 1] ||
                //   m_sma7Buffer[idx + 2] <= m_sma8Buffer[idx + 2] ||
                //   m_sma7Buffer[idx + 3] <= m_sma8Buffer[idx + 3] ||
                //   m_sma6Buffer[idx + 1] <= m_sma7Buffer[idx + 1] ||
                //   m_sma6Buffer[idx + 2] <= m_sma7Buffer[idx + 2] ||
                //   m_sma6Buffer[idx + 3] <= m_sma7Buffer[idx + 3])
                //{
                //    if(m_rsiBuffer[idx] > 70)
                //       //&& m_rsiBuffer[idx + 1] < 70
                //       //&& m_rsiBuffer[idx + 2] < 70)
                //    {
                //        //if(m_volBuffer[idx] > m_volBuffer[idx + 1])
                //            now = true;
                //    }
                //    return true;
                //}
            }
            return false;
        }
        
        bool IsSellSignal(int idx)
        {
            return (m_signalBuffer[idx] > 0 && m_signalBuffer[idx] < m_sma8Buffer[idx]);
        }
        bool IsBuySignal(int idx)
        {
            return (m_signalBuffer[idx] > 0 && m_signalBuffer[idx] > m_sma8Buffer[idx]);
        }
        int GetLastSignal(int beforeIdx)
        {
            for(int idx = beforeIdx + 1; idx < ArraySize(m_sma8Buffer) && idx < ArraySize(m_signalBuffer); idx++)
            {
                if(m_signalBuffer[idx] > 0)
                    return idx;
            }
            return -1;
        }
        bool IsLastTimeOpsDiffNow()
        {
            long totalSeconds = TimeCurrent() - m_lastTimeOps;
            
            if((m_tf == PERIOD_D1 && totalSeconds >= PeriodSeconds(PERIOD_D1)) ||
               (m_tf == PERIOD_H12 && totalSeconds >= PeriodSeconds(PERIOD_H12)) ||
               (m_tf == PERIOD_H4 && totalSeconds >= PeriodSeconds(PERIOD_H4)) ||
               (m_tf == PERIOD_H2 && totalSeconds >= PeriodSeconds(PERIOD_H2)) ||
               (m_tf == PERIOD_H1 && totalSeconds >= PeriodSeconds(PERIOD_H1)) ||
               (m_tf == PERIOD_M30 && totalSeconds >= PeriodSeconds(PERIOD_M30)) ||
               (m_tf == PERIOD_M15 && totalSeconds >= PeriodSeconds(PERIOD_M15)) ||
               (m_tf == PERIOD_M5 && totalSeconds >= PeriodSeconds(PERIOD_M5)) ||
               (m_tf == PERIOD_M1 && totalSeconds >= PeriodSeconds(PERIOD_M1))
              )
                return true;
                
            if((_Period == PERIOD_D1 && m_tf == PERIOD_CURRENT && totalSeconds >= PeriodSeconds(PERIOD_D1)) ||
               (_Period == PERIOD_H12 && m_tf == PERIOD_CURRENT && totalSeconds >= PeriodSeconds(PERIOD_H12)) ||
               (_Period == PERIOD_H4 && m_tf == PERIOD_CURRENT && totalSeconds >= PeriodSeconds(PERIOD_H4)) ||
               (_Period == PERIOD_H2 && m_tf == PERIOD_CURRENT && totalSeconds >= PeriodSeconds(PERIOD_H2)) ||
               (_Period == PERIOD_H1 && m_tf == PERIOD_CURRENT && totalSeconds >= PeriodSeconds(PERIOD_H1)) ||
               (_Period == PERIOD_M30 && m_tf == PERIOD_CURRENT && totalSeconds >= PeriodSeconds(PERIOD_M30)) ||
               (_Period == PERIOD_M15 && m_tf == PERIOD_CURRENT && totalSeconds >= PeriodSeconds(PERIOD_M15)) ||
               (_Period == PERIOD_M5 && m_tf == PERIOD_CURRENT && totalSeconds >= PeriodSeconds(PERIOD_M5)) ||
               (_Period == PERIOD_M1 && m_tf == PERIOD_CURRENT && totalSeconds >= PeriodSeconds(PERIOD_M1))
              )
                return true;
            return false;
        }
        void TimeAdd(datetime &target, int hours, int minutes, int seconds)
        {
            target += seconds;
            target += minutes * PeriodSeconds(PERIOD_M1);
            target += hours * PeriodSeconds(PERIOD_H1);
        }
        
};