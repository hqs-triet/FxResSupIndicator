
#include <Trade\PositionInfo.mqh>
#include <trade/trade.mqh>
#include  "..\ExpertWrapper.mqh"
#include  "..\Common.mqh"
#include  "IAlgorithm.mqh"
#resource "\\Indicators\\Examples\macd-2.ex5"

// ===================================================================
// Tham số đầu vào [start]
// ===================================================================
input double InpEma200MacdTpRatio = 1.2;  // |- Tỉ lệ TP so với SL
input int    InpEma200MacdSLMinPoint = 150; // |- Số point nhỏ nhất của SL
input int    InpEma200MacdSLMaxPoint = 500; // |- Số point lớn nhất của SL
// ===================================================================
// Tham số đầu vào [end]
// ===================================================================

// ===================================================================
// Khai báo đối tượng trade ngẫu nhiên, thừa kế IAlgorithm
// ===================================================================
class CEma200Macd: public IAlgorithm
{
    private:
        double m_lot;
        
        double m_macdFastBuffer[], m_macdSlowBuffer[], m_macdHistogramBuffer[], m_ema200Buffer[];
        int m_macdHandler, m_ema200Handler;
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
            
            // Macd
            ArraySetAsSeries(m_macdFastBuffer, true);
            ArraySetAsSeries(m_macdSlowBuffer, true);
            ArraySetAsSeries(m_macdHistogramBuffer, true);
            m_macdHandler = iCustom(m_symbolCurrency, m_tf, "::Indicators\\Examples\\macd-2",
                                                 12,
                                                 26,
                                                 9,
                                                 PRICE_CLOSE // using the close prices
                                                );
            
            // EMA200
            ArraySetAsSeries(m_ema200Buffer, true);
            m_ema200Handler = iMA(m_symbolCurrency, m_tf, 200, 0, MODE_EMA, PRICE_CLOSE);
            
            m_lot = 0.01;
            return INIT_SUCCEEDED;
        }
        
        // =======================================================
        void Process(int limit)
        {
            m_infoCurrency.refresh();
            int bars = Bars(m_symbolCurrency, m_tf);
            CopyBuffer(m_macdHandler, 0, 0, bars, m_macdFastBuffer);
            CopyBuffer(m_macdHandler, 1, 0, bars, m_macdSlowBuffer);
            CopyBuffer(m_macdHandler, 2, 0, bars, m_macdHistogramBuffer);
            CopyBuffer(m_ema200Handler, 0, 0, bars, m_ema200Buffer);
            
            int slPoints = 0, tpPoints = 0;
            double sl, tp;
            string comment = "";

            MqlDateTime currTime;
            TimeToStruct(TimeCurrent(), currTime);
            if(currTime.hour <= 7 || currTime.hour >= 20)
                return;
            
            if(GetActivePositions(m_symbolCurrency, m_magicNumber, true, true, m_prefixComment) == 0)
            {
                // SELL
                if(m_infoCurrency.high(1) < m_ema200Buffer[1]
                   && m_macdFastBuffer[1] > 0
                   && m_macdSlowBuffer[1] > 0
                   && m_macdHistogramBuffer[2] >= 0
                   && m_macdHistogramBuffer[1] < 0
                   )
                {
                    sl = m_ema200Buffer[1];
                    
                    double entry = m_infoCurrency.bid();
                    tp = entry - MathAbs(sl - entry) * InpEma200MacdTpRatio;
                    
                    slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(sl - entry));
                    if(slPoints > InpEma200MacdSLMaxPoint || slPoints < InpEma200MacdSLMinPoint)
                        return;
                    tpPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(tp - entry));
                    comment = m_prefixComment + ";01;" + slPoints + ";" + tpPoints;
                    
                    m_trader.Sell(m_lot, m_symbolCurrency, entry, sl, tp, comment);
                }
                
                // BUY
                ENUM_TIMEFRAMES tf = m_infoCurrency.timeframe();
                double low = m_infoCurrency.low(1);
                if(m_infoCurrency.low(1) > m_ema200Buffer[1]
                   && m_macdFastBuffer[1] < 0
                   && m_macdSlowBuffer[1] < 0
                   && m_macdHistogramBuffer[2] <= 0
                   && m_macdHistogramBuffer[1] > 0
                   )
                {
                    sl = m_ema200Buffer[1];
                    
                    double entry = m_infoCurrency.ask();
                    tp = entry + MathAbs(sl - entry) * InpEma200MacdTpRatio;
                    slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(sl - entry));
                    if(slPoints > InpEma200MacdSLMaxPoint || slPoints < InpEma200MacdSLMinPoint)
                        return;
                    tpPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(tp - entry));
                    comment = m_prefixComment + ";01;" + slPoints + ";" + tpPoints;
                    
                    m_trader.Buy(m_lot, m_symbolCurrency, entry, sl, tp, comment);
                }
            }
            
        }
};