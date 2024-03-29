
#resource "\\Indicators\\ForexProEA_HunterSignal.ex5"

#include <Trade\PositionInfo.mqh>
#include <trade/trade.mqh>
#include  "..\ExpertWrapper.mqh"
#include  "..\Common.mqh"
#include  "IAlgorithm.mqh"
//#resource "\\Indicators\\Examples\\ZigZagColor.ex5"

//#resource "\\Indicators\\ForexProEA_6_4_Fan.ex5"
//#resource "\\Indicators\\ForexProEA_6_6_MultipleSMA.ex5"
//#resource "\\Indicators\\ForexProEA_6_7_StrongMove.ex5"
//#resource "\\Indicators\\ForexProEA_HunterSignal.ex5"

// ===================================================================
// Tham số đầu vào [start]
// ===================================================================
input double InpFixedLot = 0.01;
input double InpLotPercent = 0;
input int InpSL = 200;
input double InpSLAtr = 2;  // Or use ATR (prior)
input double InpTpRatio = 4;
//input string InpFanPeriods = "4;8;12;16;20;24;28;32;50";
//input int    InpFanCrossPeriod = 20;
// ===================================================================
// Tham số đầu vào [end]
// ===================================================================

// ===================================================================
// Class xử lý giao dịch theo mô hình EMA tỏa ra, thừa kế IAlgorithm
// ===================================================================
class CPerfect2Indicator: public IAlgorithm
{
    private:
        double m_lot;
        //double m_strongMoveSignalBuyBuffer[], 
        //       m_strongMoveSignalSellBuffer[], 
        //       m_strongMoveSignalCutBuffer[], 
        //       m_fanBuyBuffer[], m_fanSellBuffer[];
        //int m_fanHandler, m_strongMoveHandler;
        double m_atrBuffer[];
        int m_atrHandler;
        
        double m_hunterBuyBuffer[], m_hunterSellBuffer[];
        int m_hunterHandler;
    public:
        void Vol(double vol)
        {
            m_lot = vol;
        }
        int Init(string symbol, ENUM_TIMEFRAMES tf, 
                       CTrade &trader, AllSeriesInfo &infoCurrency,
                       string prefixComment, ulong magicNumber)
        {
            IAlgorithm::Init(symbol, tf, trader, infoCurrency, prefixComment, magicNumber);
            
            //InitSeries(m_fanBuyBuffer);
            //InitSeries(m_fanSellBuffer);
            //m_fanHandler = 
            //iCustom(m_symbolCurrency, m_tf, 
            //                        "::Indicators\\ForexProEA_6_6_MultipleSMA", ""
            //                        , "4;8;12;16;20;24;28;32;200"
            //                        );

            InitSeries(m_hunterBuyBuffer);
            InitSeries(m_hunterSellBuffer);
            m_hunterHandler = iCustom(m_symbolCurrency, m_tf, "::Indicators\\ForexProEA_HunterSignal"
                                        , "4;8;12;16;20;24;28;32;200", MODE_SMA, 20, 30);
                                      
            //InitSeries(m_strongMoveSignalBuyBuffer);
            //InitSeries(m_strongMoveSignalSellBuffer);
            //InitSeries(m_strongMoveSignalCutBuffer);
            //m_strongMoveHandler = iCustom(m_symbolCurrency, m_tf,
            //                        "::Indicators\\ForexProEA_6_7_StrongMove");
            //iRSI(m_symbolCurrency, m_tf, 14, PRICE_CLOSE);
            //iADXWilder(m_symbolCurrency, m_tf, 14);
            
            InitSeries(m_atrBuffer);
            m_atrHandler = iATR(m_symbolCurrency, m_tf, 14);
            m_lot = InpFixedLot;
            return INIT_SUCCEEDED;
        }
        
        // =======================================================
        void Process(int limit)
        {
            
            if(limit <= 0)
                return;
            
            m_infoCurrency.refresh();
            
            //MoveSLToEntryByProfitVsSL(m_symbolCurrency, m_magicNumber, 1, m_trader, 5, true, true, m_prefixComment);
            
            int bars = Bars(m_symbolCurrency, m_tf);
            CopyBuffer(m_hunterHandler, 0, 0, bars, m_hunterBuyBuffer);
            CopyBuffer(m_hunterHandler, 1, 0, bars, m_hunterSellBuffer);
        
            //CopyBuffer(m_strongMoveHandler, 0, 0, bars, m_strongMoveSignalBuyBuffer);
            //CopyBuffer(m_strongMoveHandler, 1, 0, bars, m_strongMoveSignalSellBuffer);
            //CopyBuffer(m_strongMoveHandler, 2, 0, bars, m_strongMoveSignalCutBuffer);
            //CopyBuffer(m_fanHandler, 20, 0, bars, m_fanBuyBuffer);
            //CopyBuffer(m_fanHandler, 21, 0, bars, m_fanSellBuffer);
            CopyBuffer(m_atrHandler, 0, 0, bars, m_atrBuffer);
            
            int openPos = GetActivePositions(m_symbolCurrency, m_magicNumber, true, true, m_prefixComment);
            if(openPos == 0)
            {
                ProcessBuy(limit);
                ProcessSell(limit);
            }
        }
        void ProcessBuy(int limit)
        {
            if(CanBuy())
            {
                double entry = m_infoCurrency.ask();
                entry = m_infoCurrency.ask() - PointsToPriceShift(m_symbolCurrency, InpSL);
                if(InpSLAtr > 0)
                    entry = m_infoCurrency.ask() - m_atrBuffer[1];
                    
                double sl = entry - PointsToPriceShift(m_symbolCurrency, InpSL);
                if(InpSLAtr > 0)
                    sl = entry - m_atrBuffer[1] * InpSLAtr;
                int slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - sl));
                double tp = entry + MathAbs(entry - sl) * InpTpRatio;
                int tpPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - tp));
                string comment = m_prefixComment + ";01;" + (string)slPoints + ";" + (string)tpPoints;
                if(InpLotPercent > 0)
                    m_lot = PointsToLots(m_symbolCurrency, InpLotPercent, slPoints);
                ResetLastError();
                if(!m_trader.Buy(m_lot, m_symbolCurrency, 0, sl, tp, comment))
                //if(!m_trader.BuyLimit(m_lot, entry, m_symbolCurrency, sl, tp, ORDER_TIME_DAY, 0, comment))
                {
                    Print("Error: " + (string)GetLastError());
                }
            }
        }
        
        void ProcessSell(int limit)
        {
            if(CanSell())
            {
            
                double entry = m_infoCurrency.bid();
                entry = m_infoCurrency.bid() + PointsToPriceShift(m_symbolCurrency, InpSL);
                if(InpSLAtr > 0)
                    entry = m_infoCurrency.bid() + m_atrBuffer[1];
                    
                double sl = entry + PointsToPriceShift(m_symbolCurrency, InpSL);
                if(InpSLAtr > 0)
                    sl = entry + m_atrBuffer[1] * InpSLAtr;
                int slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - sl));
                double tp = entry - MathAbs(entry - sl) * InpTpRatio;
                int tpPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - tp));
                string comment = m_prefixComment + ";01;" + (string)slPoints + ";" + (string)tpPoints;
                if(InpLotPercent > 0)
                    m_lot = PointsToLots(m_symbolCurrency, InpLotPercent, slPoints);
                ResetLastError();
                if(!m_trader.Sell(m_lot, m_symbolCurrency, 0, sl, tp, comment))
                //if(!m_trader.SellLimit(m_lot, entry, m_symbolCurrency, sl, tp, ORDER_TIME_DAY, 0, comment))
                {
                    Print("Error: " + (string)GetLastError());
                }
            }
        }
        
        bool CanSell()
        {
//            if(m_strongMoveSignalSellBuffer[1] > 0)
//            {
//                int firstSignalFan = GetFirstPoint(m_fanSellBuffer);
//                int secondSignalSellFan = GetFirstPoint(m_fanSellBuffer, firstSignalFan + 1);
//                int secondSignalBuyFan = GetFirstPoint(m_fanBuyBuffer, firstSignalFan + 1);
//                if(firstSignalFan < 0 || secondSignalSellFan < 0 || secondSignalBuyFan < 0)
//                    return false;
//                    
//                if(firstSignalFan > InpFanCrossPeriod 
//                   //&& secondSignalSellFan < secondSignalBuyFan
//                   )
//                    return false;
//                    
//                return true;
//                //double minPrice = GetMinPriceRange(m_infoCurrency, 2, 40, true);
//                //if(m_strongMoveSignalSellBuffer[1] < minPrice)
//                //    return true;
//            }
            return m_hunterSellBuffer[1] > 0;
        }
        
        bool CanBuy()
        {
//            if(m_strongMoveSignalBuyBuffer[1] > 0)
//            {
//                int firstSignalFan = GetFirstPoint(m_fanBuyBuffer);
//                int secondSignalSellFan = GetFirstPoint(m_fanSellBuffer, firstSignalFan + 1);
//                int secondSignalBuyFan = GetFirstPoint(m_fanBuyBuffer, firstSignalFan + 1);
//                if(firstSignalFan < 0 || secondSignalSellFan < 0 || secondSignalBuyFan < 0)
//                    return false;
//                    
//                if(firstSignalFan > InpFanCrossPeriod
//                   //&& secondSignalSellFan > secondSignalBuyFan
//                   )
//                    return false;
//                
//                return true;
//                //double maxPrice = GetMaxPriceRange(m_infoCurrency, 2, 40, true);
//                //if(m_strongMoveSignalBuyBuffer[1] > maxPrice)
//                //    return true;
//            }
//            return false;
            return m_hunterBuyBuffer[1] > 0;
        }
        
};