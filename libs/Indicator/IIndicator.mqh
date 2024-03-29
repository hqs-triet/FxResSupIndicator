#include <Trade\PositionInfo.mqh>
#include <trade/trade.mqh>
#include  "..\ExpertWrapper.mqh"
class IIndicator
{
    protected:
        string m_symbolCurrency;
        AllSeriesInfo m_infoCurrency;
        ENUM_TIMEFRAMES m_tf;
        bool m_isInitialized;
    public:
        IIndicator()
        {
            m_isInitialized = false;
        }
        virtual int Init(string symbol, ENUM_TIMEFRAMES tf,
                         AllSeriesInfo &infoCurrency){
            m_symbolCurrency = symbol;
            m_tf = tf;
            m_infoCurrency = infoCurrency;
            return INIT_SUCCEEDED;
        }
        virtual void Refresh(int limit) = 0;
};