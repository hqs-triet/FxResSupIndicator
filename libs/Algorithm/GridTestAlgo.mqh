
#include <Trade\PositionInfo.mqh>
#include <trade/trade.mqh>
#include  "..\ExpertWrapper.mqh"
#include  "..\Common.mqh"
#include  "IAlgorithm.mqh"
#include  "..\PriceAction.mqh"
//#resource "\\Indicators\\Examples\\ZigZagColor.ex5"

// ===================================================================
// Tham số đầu vào [start]
// ===================================================================

// ===================================================================
// Tham số đầu vào [end]
// ===================================================================

// ===================================================================
// Class xử lý giao dịch theo mô hình EMA tỏa ra, thừa kế IAlgorithm
// ===================================================================
class CGridTest: public IAlgorithm
{
    private:
        double m_lot;
    public:
        void Vol(double vol)
        {
            m_lot = vol;
        }
        CGridTest()
        {
            m_lot = 0.01;
        }
        
        // =======================================================
        void Process(int limit)
        {
            m_infoCurrency.refresh();
            
            if(limit <= 0)
                return;
                
            int countPos = GetActivePositions(m_symbolCurrency, m_magicNumber, true, true, m_prefixComment);
            if(countPos == 0)
            {
                string comment = m_prefixComment + ";10000;"
                m_trader.Sell(m_lot, m_symbolCurrency, 0, 0, 0, comment);
                m_trader.Buy(m_lot, m_symbolCurrency, 0, 0, 0, comment);
            }
        }
};