
#include <Trade\PositionInfo.mqh>
#include <trade/trade.mqh>
#include  "..\ExpertWrapper.mqh"
#include  "..\Common.mqh"
#include  "IAlgorithm.mqh"

// ===================================================================
// Tham số đầu vào [start]
// ===================================================================
input double InpAdxBBEma200TpRatio = 1.2;  // |- Tỉ lệ TP so với SL
input int    InpAdxBBEma200SLMinPoint = 150; // |- Số point nhỏ nhất của SL
input int    InpAdxBBEma200SLMaxPoint = 500; // |- Số point lớn nhất của SL
// ===================================================================
// Tham số đầu vào [end]
// ===================================================================

// ===================================================================
// Khai báo đối tượng trade ngẫu nhiên, thừa kế IAlgorithm
// ===================================================================
class CAdxBBEma200: public IAlgorithm
{
    private:
        double m_lot;
        
        double m_ema200Buffer[], m_adxBuffer[], m_adxDIPlusBuffer[], m_adxDIMinusBuffer[];
        double m_bbTLBuffer[], m_bbMLBuffer[], m_bbBLBuffer[];
        int m_ema200Handler, m_adxHandler, m_bbHandler;
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
            
            // EMA200
            ArraySetAsSeries(m_ema200Buffer, true);
            m_ema200Handler = iMA(m_symbolCurrency, m_tf, 200, 0, MODE_EMA, PRICE_CLOSE);
            
            // ADX
            ArraySetAsSeries(m_adxBuffer, true);
            m_adxHandler = iADXWilder(m_symbolCurrency, m_tf, 14);
            
            // BB
            ArraySetAsSeries(m_bbTLBuffer, true);
            ArraySetAsSeries(m_bbMLBuffer, true);
            ArraySetAsSeries(m_bbBLBuffer, true);
            m_bbHandler = iBands(m_symbolCurrency, m_tf, 20, 0, 2, PRICE_CLOSE);
            
            
            // For test only
            //iMA(m_symbolCurrency, PERIOD_H4, 20, 0, MODE_EMA, PRICE_CLOSE);
            
            m_lot = 0.01;
            return INIT_SUCCEEDED;
        }
        
        // =======================================================
        void Process(int limit)
        {
            m_infoCurrency.refresh();
            
            int bars = Bars(m_symbolCurrency, m_tf);
            CopyBuffer(m_ema200Handler, 0, 0, bars, m_ema200Buffer);
            
            CopyBuffer(m_adxHandler, 0, 0, bars, m_adxBuffer);
            CopyBuffer(m_adxHandler, 1, 0, bars, m_adxDIPlusBuffer);
            CopyBuffer(m_adxHandler, 2, 0, bars, m_adxDIMinusBuffer);
            
            CopyBuffer(m_bbHandler, 0, 0, bars, m_bbMLBuffer);
            CopyBuffer(m_bbHandler, 1, 0, bars, m_bbTLBuffer);
            CopyBuffer(m_bbHandler, 2, 0, bars, m_bbBLBuffer);
            
            int slPoints = 0, tpPoints = 0;
            double sl, tp;
            string comment = "";

            MqlDateTime currTime;
            TimeToStruct(TimeCurrent(), currTime);
            if(currTime.hour <= 10 || currTime.hour >= 20)
                return;
            
            if(GetActivePositions(m_symbolCurrency, m_magicNumber, true, true, m_prefixComment) == 0)
            {
                if(m_adxBuffer[2] < 25 && m_adxBuffer[1] > 25)
                {
                    // SELL
                    if(m_infoCurrency.close(1) < m_bbMLBuffer[1] && m_infoCurrency.close(1) < m_ema200Buffer[1])
                    {
                        sl = m_ema200Buffer[1];
                        if(sl > m_bbTLBuffer[1])
                            sl = m_bbTLBuffer[1];
                        double entry = m_infoCurrency.bid();
                        tp = entry - MathAbs(sl - entry) * InpAdxBBEma200TpRatio;
                        slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(sl - entry));
                        if(slPoints > InpAdxBBEma200SLMaxPoint || slPoints < InpAdxBBEma200SLMinPoint)
                            return;
                        tpPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(tp - entry));
                        comment = m_prefixComment + ";01;" + slPoints + ";" + tpPoints;
                        m_trader.Sell(m_lot, m_symbolCurrency, entry, sl, tp, comment);
                    }
                    
                    // BUY
                    if(m_infoCurrency.close(1) > m_bbMLBuffer[1] && m_infoCurrency.close(1) > m_ema200Buffer[1])
                    {
                        sl = m_ema200Buffer[1];
                        if(sl < m_bbBLBuffer[1])
                            sl = m_bbBLBuffer[1];
                        double entry = m_infoCurrency.ask();
                        tp = entry + MathAbs(sl - entry) * InpAdxBBEma200TpRatio;
                        slPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(sl - entry));
                        if(slPoints > InpAdxBBEma200SLMaxPoint || slPoints < InpAdxBBEma200SLMinPoint)
                            return;
                        tpPoints = PriceShiftToPoints(m_symbolCurrency, MathAbs(tp - entry));
                        comment = m_prefixComment + ";01;" + slPoints + ";" + tpPoints;
                        m_trader.Buy(m_lot, m_symbolCurrency, entry, sl, tp, comment);
                    }
                    
                }
            }
            
        }
};