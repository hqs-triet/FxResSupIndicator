
#include <Trade\PositionInfo.mqh>
#include <trade/trade.mqh>
#include  "..\ExpertWrapper.mqh"
#include  "..\Common.mqh"
#include  "IIndicator.mqh"

// ===================================================================
// Tham số đầu vào [start]
// ===================================================================

// ===================================================================
// Tham số đầu vào [end]
// ===================================================================

// ===================================================================
// Khai báo đối tượng chỉ báo cho Ichimoku, thừa kế IAlgorithm
// ===================================================================
class CIchimoku: public IIndicator
{
    private:
        double  m_ichiMokuTenkanBuffer[];
        double  m_ichiMokuKijunBuffer[];
        double  m_ichiMokuSpanABuffer[];
        double  m_ichiMokuSpanBBuffer[];
        double  m_ichiMokuChikouSpanBuffer[];
        int     m_ichimokuHandler;
        int m_tenkanPeriod, m_kijunPeriod, m_senkouSpanBPeriod;
        ENUM_APPLIED_PRICE m_appliedPrice;
    public:
        
        int Init(string symbol, ENUM_TIMEFRAMES tf, 
                 AllSeriesInfo &infoCurrency, 
                 int tenkanPeriod = 9, int kijunPeriod = 26, int senkouSpanBPeriod = 52)
        {
            IIndicator::Init(symbol, tf, infoCurrency);
            
            m_tenkanPeriod = tenkanPeriod;
            m_kijunPeriod = kijunPeriod;
            m_senkouSpanBPeriod = senkouSpanBPeriod;
            
            ArraySetAsSeries(m_ichiMokuTenkanBuffer, true);
            ArraySetAsSeries(m_ichiMokuKijunBuffer, true);
            ArraySetAsSeries(m_ichiMokuSpanABuffer, true);
            ArraySetAsSeries(m_ichiMokuSpanBBuffer, true);
            ArraySetAsSeries(m_ichiMokuChikouSpanBuffer, true);
           
            m_ichimokuHandler = iIchimoku(m_symbolCurrency, m_tf, 
                                          m_tenkanPeriod, m_kijunPeriod, m_senkouSpanBPeriod);
            if(m_ichimokuHandler == INVALID_HANDLE)
            {
                Print("Không khởi tạo được Ichimoku (" + 
                      (string)m_tenkanPeriod + "," + 
                      (string)m_kijunPeriod + "," + 
                      (string)m_senkouSpanBPeriod + ")");
                m_isInitialized = false;
                return INIT_FAILED;
            }
            m_isInitialized = true;
            return INIT_SUCCEEDED;
        }
        
        // =======================================================
        void Refresh(int limit)
        {
            m_infoCurrency.refresh();
            int bars = Bars(m_symbolCurrency, m_tf);
            
            CopyBuffer(m_ichimokuHandler, 0, 0, bars, m_ichiMokuTenkanBuffer);
            CopyBuffer(m_ichimokuHandler, 1, 0, bars, m_ichiMokuKijunBuffer);
            // Up cloud:    SpanA > SpanB
            // Down cloude: SpanA < SpanB
            CopyBuffer(m_ichimokuHandler, 2, 0, bars, m_ichiMokuSpanABuffer);
            CopyBuffer(m_ichimokuHandler, 3, 0, bars, m_ichiMokuSpanBBuffer);
            CopyBuffer(m_ichimokuHandler, 4, 0, bars, m_ichiMokuChikouSpanBuffer);
        }
        double Value(int idx)
        {
            if(m_isInitialized)
            {
                if(idx < ArraySize(m_ichiMokuTenkanBuffer))
                    return m_ichiMokuTenkanBuffer[idx];
            }
            return 0;
        }
        double Tenkan(int idx)
        {
            if(m_isInitialized)
            {
                if(idx < ArraySize(m_ichiMokuTenkanBuffer))
                    return m_ichiMokuTenkanBuffer[idx];
            }
            return 0;
        }
        double Kijun(int idx) 
        {
            if(m_isInitialized)
            {
                if(idx < ArraySize(m_ichiMokuKijunBuffer))
                    return m_ichiMokuKijunBuffer[idx];
            }
            return 0;
        }
        double SenkouSpanA(int idx) 
        {
            if(m_isInitialized)
            {
                if(idx < ArraySize(m_ichiMokuSpanABuffer))
                    return m_ichiMokuSpanABuffer[idx];
            }
            return 0;
        }
        double SenkouSpanB(int idx) 
        {
            if(m_isInitialized)
            {
                if(idx < ArraySize(m_ichiMokuSpanBBuffer))
                    return m_ichiMokuSpanBBuffer[idx];
            }
            return 0;
        }
        double ChikouSpan(int idx) 
        {
            if(m_isInitialized)
            {
                if(idx < ArraySize(m_ichiMokuSpanBBuffer))
                    return m_ichiMokuSpanBBuffer[idx];
            }
            return 0;
        }
};