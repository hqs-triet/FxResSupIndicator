
#include <Trade\PositionInfo.mqh>
#include <trade/trade.mqh>
#include  "..\ExpertWrapper.mqh"
#include  "..\Common.mqh"
#include  "IAlgorithm.mqh"
#include  "..\..\libs\Condition\EmaFanOut.mqh"
#include  "..\..\libs\Indicator\Rsi.mqh"

// ===================================================================
// Tham số đầu vào [start]
// ===================================================================
input int   InpEmaFanMinSL = 100;
input int   InpEmaFanSLDistance = 50; // Một khoảng cách phụ thêm cho SL
input double   InpEmaFanTpRatio = 3;  // Tỉ lệ TP so với SL
input bool InpEmaFanUseM1 = true;
input bool InpEmaFanUseM5 = true;
input bool InpEmaFanUseM15 = true;
input bool InpEmaFanUseH1 = true;
input bool InpEmaFanUseH4 = true;
input bool InpEmaFanUseD1 = true;
input bool InpEmaFanUseW1 = true;
input int  InpEmaFanConsolidationPeriod = 20;
input bool  InpEmaFanLimitTradeTime = true;     // Chỉ định thời gian giao dịch?
input uint   InpEmaFanLimitTradeTimeStart = 13;  // |- Thời gian giao dịch >= Giờ bắt đầu
input uint   InpEmaFanLimitTradeTimeEnd = 23;    // |- Thời gian giao dịch < Giở kết thúc
// ===================================================================
// Tham số đầu vào [end]
// ===================================================================

// ===================================================================
// Class xử lý giao dịch theo mô hình EMA tỏa ra, thừa kế IAlgorithm
// ===================================================================
class CEmaFan: public IAlgorithm
{
    private:
        double m_lot;
        CEmaFanOut m_emFanM1, m_emFanM5, m_emFanM15, m_emFanH1, m_emFanH4, m_emFanD1, m_emFanW1;
        //CRsi m_rsi;
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
            
            // Khởi tạo đối tượng: mô hình cái nêm
            uint emas[] = {4, 8, 12, 16, 20, 24, 30, 34};
            if(InpEmaFanUseM1)
                if(m_emFanM1.Init(m_symbolCurrency, PERIOD_M1, m_infoCurrency, emas) == INIT_FAILED)
                    return false;
            if(InpEmaFanUseM5)
                if(m_emFanM5.Init(m_symbolCurrency, PERIOD_M5, m_infoCurrency, emas) == INIT_FAILED)
                    return false;
            if(InpEmaFanUseM15)
                if(m_emFanM15.Init(m_symbolCurrency, PERIOD_M15, m_infoCurrency, emas) == INIT_FAILED)
                    return false;
            if(InpEmaFanUseH1)
                if(m_emFanH1.Init(m_symbolCurrency, PERIOD_H1, m_infoCurrency, emas) == INIT_FAILED)
                    return false;
            if(InpEmaFanUseH4)
                if(m_emFanH4.Init(m_symbolCurrency, PERIOD_H4, m_infoCurrency, emas) == INIT_FAILED)
                    return false;
            if(InpEmaFanUseD1)
                if(m_emFanD1.Init(m_symbolCurrency, PERIOD_D1, m_infoCurrency, emas) == INIT_FAILED)
                    return false;
            if(InpEmaFanUseW1)
                if(m_emFanW1.Init(m_symbolCurrency, PERIOD_W1, m_infoCurrency, emas) == INIT_FAILED)
                    return false;
            
            //m_rsi.Init(m_symbolCurrency, m_tf, m_infoCurrency, 14, PRICE_CLOSE);
            
            //iOsMA(m_symbolCurrency, m_tf, 12, 26, 9, PRICE_CLOSE);
            m_lot = 0.01;
            return INIT_SUCCEEDED;
        }
        
        // =======================================================
        void Process(int limit)
        {
            if(limit <= 0)
                return;

            m_infoCurrency.refresh();
            //m_rsi.Refresh(limit);
            
            if(InpEmaFanLimitTradeTime)
            {
                MqlDateTime currTime;
                TimeToStruct(TimeCurrent(), currTime);
                if(currTime.hour < InpEmaFanLimitTradeTimeStart 
                   || currTime.hour >= InpEmaFanLimitTradeTimeEnd)
                    return;
            }
            
            // Xử lý điều kiện
            if(InpEmaFanUseM1)
                m_emFanM1.Process(limit);
            if(InpEmaFanUseM5)
                m_emFanM5.Process(limit);
            if(InpEmaFanUseM15)
                m_emFanM15.Process(limit);
            if(InpEmaFanUseH1)
                m_emFanH1.Process(limit);
            if(InpEmaFanUseH4)
                m_emFanH4.Process(limit);
            if(InpEmaFanUseD1)
                m_emFanD1.Process(limit);
            if(InpEmaFanUseW1)
                m_emFanW1.Process(limit);
            
            if(GetActivePositions(m_symbolCurrency, m_magicNumber, true, true, m_prefixComment) == 0)
            {
                // Phát hiện tín hiệu
                ProcessBuy(limit);
                    
                ProcessSell(limit);
            }
                
        }
        void ProcessBuy(int limit)
        {
            bool canBuy = true;
            if(InpEmaFanUseW1)
                canBuy = canBuy && m_emFanW1.IsMatched(limit, ENUM_EMAFAN_UP, 1);
            if(InpEmaFanUseD1)
            {
                if(!InpEmaFanUseH4 && !InpEmaFanUseH1 && !InpEmaFanUseM15 && !InpEmaFanUseM5 & !InpEmaFanUseM1)
                    canBuy = canBuy && m_emFanD1.IsMatched(limit, ENUM_EMAFAN_UP);
                else
                    canBuy = canBuy && m_emFanD1.IsMatched(limit, ENUM_EMAFAN_UP, 1);
            }
            if(InpEmaFanUseH4)
            {
                if(!InpEmaFanUseH1 && !InpEmaFanUseM15 && !InpEmaFanUseM5 & !InpEmaFanUseM1)
                    canBuy = canBuy && m_emFanH4.IsMatched(limit, ENUM_EMAFAN_UP);
                else
                    canBuy = canBuy && m_emFanH4.IsMatched(limit, ENUM_EMAFAN_UP, 1);
            }
            if(InpEmaFanUseH1)
            {
                if(!InpEmaFanUseM15 && !InpEmaFanUseM5 & !InpEmaFanUseM1)
                    canBuy = canBuy && m_emFanH1.IsMatched(limit, ENUM_EMAFAN_UP);
                else
                    canBuy = canBuy && m_emFanH1.IsMatched(limit, ENUM_EMAFAN_UP, 1);
            }
            if(InpEmaFanUseM15)
            {
                if(!InpEmaFanUseM5 && !InpEmaFanUseM1)
                    canBuy = canBuy && m_emFanM15.IsMatched(limit, ENUM_EMAFAN_UP);
                else
                    canBuy = canBuy && m_emFanM15.IsMatched(limit, ENUM_EMAFAN_UP, 1);
            }
            if(InpEmaFanUseM5)
            {
                if(!InpEmaFanUseM1)
                    canBuy = canBuy && m_emFanM5.IsMatched(limit, ENUM_EMAFAN_UP);
                else
                    canBuy = canBuy && m_emFanM5.IsMatched(limit, ENUM_EMAFAN_UP, 1);
            }
            if(InpEmaFanUseM1)
                canBuy = canBuy && m_emFanM1.IsMatched(limit, ENUM_EMAFAN_UP);
            
            //canBuy = canBuy && IsConsolidate();
            canBuy = canBuy && GetActivePositions(m_symbolCurrency, m_magicNumber, true, true, m_prefixComment) == 0;
            if(canBuy)
            {
                ClosePendingOrders(m_trader, m_symbolCurrency, m_magicNumber, ORDER_TYPE_BUY_LIMIT);
                ClosePendingOrders(m_trader, m_symbolCurrency, m_magicNumber, ORDER_TYPE_SELL_LIMIT);
            }
            
            if(canBuy)
            {
                Print("Phát hiện EMA fan Up!");
                double entry = getMinEma()
                               + PointsToPriceShift(m_symbolCurrency, InpEmaFanSLDistance);
                double sl = entry - PointsToPriceShift(m_symbolCurrency, InpEmaFanMinSL);
                int slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - sl));
                
                double tp = entry + MathAbs(entry - sl) * InpEmaFanTpRatio;
                int tpPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - tp));
                string comment = m_prefixComment + ";" + slPoints + ";" + tpPoints;
                
                // Thời gian hết hạn của lệnh
                datetime currTime = TimeCurrent();
                datetime expTime = currTime + 300 * 50; // tính theo mỗi M5
                
                m_trader.BuyLimit(m_lot, entry, m_symbolCurrency, sl, tp, ORDER_TIME_SPECIFIED, expTime, comment);
            }
        }
        void ProcessSell(int limit)
        {
            bool canSell = true;
            if(InpEmaFanUseW1)
                canSell = canSell && m_emFanW1.IsMatched(limit, ENUM_EMAFAN_DOWN, 1);
            if(InpEmaFanUseD1)
            {
                if(!InpEmaFanUseH4 && !InpEmaFanUseH1 && !InpEmaFanUseM15 && !InpEmaFanUseM5 && !InpEmaFanUseM1)
                    canSell = canSell && m_emFanD1.IsMatched(limit, ENUM_EMAFAN_DOWN);
                else
                    canSell = canSell && m_emFanD1.IsMatched(limit, ENUM_EMAFAN_DOWN, 1);
            }
            if(InpEmaFanUseH4)
            {
                if(!InpEmaFanUseH1 && !InpEmaFanUseM15 && !InpEmaFanUseM5 && !InpEmaFanUseM1)
                    canSell = canSell && m_emFanH4.IsMatched(limit, ENUM_EMAFAN_DOWN);
                else
                    canSell = canSell && m_emFanH4.IsMatched(limit, ENUM_EMAFAN_DOWN, 1);
            }
            if(InpEmaFanUseH1)
            {
                if(!InpEmaFanUseM15 && !InpEmaFanUseM5 && !InpEmaFanUseM1)
                    canSell = canSell && m_emFanH1.IsMatched(limit, ENUM_EMAFAN_DOWN);
                else
                    canSell = canSell && m_emFanH1.IsMatched(limit, ENUM_EMAFAN_DOWN, 1);
            }
            if(InpEmaFanUseM15)
            {
                if(!InpEmaFanUseM5 && !InpEmaFanUseM1)
                    canSell = canSell && m_emFanM15.IsMatched(limit, ENUM_EMAFAN_DOWN);
                else
                    canSell = canSell && m_emFanM15.IsMatched(limit, ENUM_EMAFAN_DOWN, 1);
            }
            if(InpEmaFanUseM5)
            {
                if(!InpEmaFanUseM1)
                    canSell = canSell && m_emFanM5.IsMatched(limit, ENUM_EMAFAN_DOWN);
                else
                    canSell = canSell && m_emFanM5.IsMatched(limit, ENUM_EMAFAN_DOWN, 1);
            }
            if(InpEmaFanUseM1)
                canSell = canSell && m_emFanM1.IsMatched(limit, ENUM_EMAFAN_DOWN);
            
            //canSell = canSell && IsConsolidate();
            canSell = canSell && GetActivePositions(m_symbolCurrency, m_magicNumber, true, true, m_prefixComment) == 0;
            if(canSell)
            {
                ClosePendingOrders(m_trader, m_symbolCurrency, m_magicNumber, ORDER_TYPE_BUY_LIMIT);
                ClosePendingOrders(m_trader, m_symbolCurrency, m_magicNumber, ORDER_TYPE_SELL_LIMIT);
            }
            if(canSell)
            {
                ClosePendingOrders(m_trader, m_symbolCurrency, m_magicNumber, ORDER_TYPE_BUY_LIMIT);
                
                Print("Phát hiện EMA fan DOWN!");
                double entry = getMaxEma() 
                               - PointsToPriceShift(m_symbolCurrency, InpEmaFanSLDistance);
                double sl = entry + PointsToPriceShift(m_symbolCurrency, InpEmaFanMinSL);
                int slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - sl));
                
                double tp = entry - MathAbs(entry - sl) * InpEmaFanTpRatio;
                int tpPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - tp));
                string comment = m_prefixComment + ";" + slPoints + ";" + tpPoints;
                
                datetime currTime = TimeCurrent();
                datetime expTime = currTime + 300 * 50; // tính theo mỗi M5
                
                m_trader.SellLimit(m_lot, entry, m_symbolCurrency, sl, tp, ORDER_TIME_SPECIFIED, expTime, comment);
            }
        }
        double getMaxEma()
        {
            if(InpEmaFanUseM1)
                return m_emFanM1.getMaxEma();
            if(InpEmaFanUseM5)
                return m_emFanM5.getMaxEma();
            if(InpEmaFanUseM15)
                return m_emFanM15.getMaxEma();
            if(InpEmaFanUseH1)
                return m_emFanH1.getMaxEma();
            if(InpEmaFanUseH4)
                return m_emFanH4.getMaxEma();
            if(InpEmaFanUseD1)
                return m_emFanD1.getMaxEma();
            if(InpEmaFanUseW1)
                return m_emFanW1.getMaxEma();
                
            return 0;
        }
        double getMinEma()
        {
            if(InpEmaFanUseM1)
                return m_emFanM1.getMinEma();
            if(InpEmaFanUseM5)
                return m_emFanM5.getMinEma();
            if(InpEmaFanUseM15)
                return m_emFanM15.getMinEma();
            if(InpEmaFanUseH1)
                return m_emFanH1.getMinEma();
            if(InpEmaFanUseH4)
                return m_emFanH4.getMinEma();
            if(InpEmaFanUseD1)
                return m_emFanD1.getMinEma();
            if(InpEmaFanUseW1)
                return m_emFanW1.getMinEma();
            return 0;
        }
        //bool IsConsolidate()
        //{
        //    for(int idx = 2; idx < InpEmaFanConsolidationPeriod; idx++)
        //    {
        //        if(m_rsi.Value(idx) >= 70 || m_rsi.Value(idx) <= 30)
        //            return false;
        //    }
        //    if(m_rsi.Value(1) <= 70 && m_rsi.Value(1) >= 30)
        //        return false;
        //    return true;
        //}
};