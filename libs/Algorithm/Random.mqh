
#include <Trade\PositionInfo.mqh>
#include <trade/trade.mqh>
#include  "..\ExpertWrapper.mqh"
#include  "..\Common.mqh"
#include  "IAlgorithm.mqh"

// ===================================================================
// Tham số đầu vào [start]
// ===================================================================
input int InpRandomSL = 800;    // |- SL của lệnh ngẫu nhiên (points)
input double InpRandomTP = 2400;  // |- TP của lệnh ngẫu nhiên (points)
// ===================================================================
// Tham số đầu vào [end]
// ===================================================================

// ===================================================================
// Khai báo đối tượng trade ngẫu nhiên, thừa kế IAlgorithm
// ===================================================================
class CRandom: public IAlgorithm
{
    private:
        double m_lot;
        
        double m_ema20Buffer[];
        int m_ema20Handler;
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
            ArraySetAsSeries(m_ema20Buffer, true);
            m_ema20Handler = iMA(m_symbolCurrency, m_tf, 20, 0, MODE_EMA, PRICE_CLOSE);
            
            // For test only
            iMA(m_symbolCurrency, PERIOD_H4, 20, 0, MODE_EMA, PRICE_CLOSE);
            
            m_lot = 0.01;
            return INIT_SUCCEEDED;
        }
        
        // =======================================================
        void Process(int limit)
        {
            m_infoCurrency.refresh();
            
            int barsEMA = Bars(m_symbolCurrency, m_tf);
            CopyBuffer(m_ema20Handler, 0, 0, barsEMA, m_ema20Buffer);
            
            int slPoints = InpRandomSL;
            int tpPoints = InpRandomTP;
            double sl, tp;
            string comment = m_prefixComment + ";01;" + slPoints + ";" + tpPoints;

            MqlDateTime currTime;
            TimeToStruct(TimeCurrent(), currTime);
            if(currTime.hour <= 11 || currTime.hour >= 13)
                return;
            
            if(GetActivePositions(m_symbolCurrency, m_magicNumber, true, true, m_prefixComment) == 0)
            {
                if(IsCandleDown(1, m_infoCurrency)
                   && m_infoCurrency.high(2) < m_ema20Buffer[1]
                   //&& m_infoCurrency.open(2) > m_ema20Buffer[1]
                   && m_infoCurrency.close(2) > m_infoCurrency.close(1))
                {
                    sl = m_infoCurrency.symbol_info().Bid() + PointsToPriceShift(m_symbolCurrency, slPoints);
                    tp = m_infoCurrency.symbol_info().Bid() - PointsToPriceShift(m_symbolCurrency, tpPoints);
                    m_trader.Sell(m_lot, m_symbolCurrency, 0, sl, tp, comment);
                }
                if(IsCandleUp(1, m_infoCurrency)
                   && m_infoCurrency.low(2) > m_ema20Buffer[1]
                   //&& m_infoCurrency.open(2) < m_ema20Buffer[1]
                   && m_infoCurrency.close(2) < m_infoCurrency.close(1))
                {
                    sl = m_infoCurrency.symbol_info().Ask() - PointsToPriceShift(m_symbolCurrency, slPoints);
                    tp = m_infoCurrency.symbol_info().Ask() + PointsToPriceShift(m_symbolCurrency, tpPoints);
                    m_trader.Buy(m_lot, m_symbolCurrency, 0, sl, tp, comment);
                }
            }
            
        }
};