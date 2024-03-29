
#include <Trade\PositionInfo.mqh>
#include <trade/trade.mqh>
#include  "..\ExpertWrapper.mqh"
#include  "..\Common.mqh"
#include  "ICondition.mqh"
#resource "\\Indicators\\Examples\ZigZagColor.ex5"
#include <ChartObjects\ChartObjectsLines.mqh>
// ===================================================================
// Tham số đầu vào [start]
// ===================================================================

// ===================================================================
// Tham số đầu vào [end]
// ===================================================================

// ===================================================================
// Class xử lý phát hiện mô hình cái nêm, thừa kế ICondition
// ===================================================================
class CWedgePattern: public ICondition
{
    private:
        double m_zigZagTopBuffer[], m_zigZagBottomBuffer[];
        int m_zigZagHandler;
        int m_period, m_depth, m_maxCandleFromCrossPoint, m_minPeriodOf2Points;
        int wedgeLastTopLeftIdx, wedgeLastTopRightIdx, wedgeLastBottomLeftIdx, wedgeLastBottomRightIdx;
        int lineId;
        bool m_rise, m_fall;
        CChartObjectTrend *m_lineTop, *m_lineBottom;
    public:
        // =======================================================
        // Cái nêm vừa phát hiện có phải là nêm tăng?
        // =======================================================
        bool IsRiseWedge()
        {
            return m_rise;
        }
        // =======================================================
        // Cái nêm vừa phát hiện có phải là nêm giảm?
        // =======================================================
        bool IsFallWedge()
        {
            return m_fall;
        }
        
        // =======================================================
        // Khởi tạo các thông số
        // =======================================================
        int Init(string symbol, ENUM_TIMEFRAMES tf, 
                 AllSeriesInfo &infoCurrency, int period, int depth, int maxCandleFromCrossPoint, int minPeriodOf2Points)
        {
            ICondition::Init(symbol, tf, infoCurrency);
            
            lineId = 0;
            m_period = period;
            m_depth = depth;
            m_maxCandleFromCrossPoint = maxCandleFromCrossPoint;
            m_minPeriodOf2Points = minPeriodOf2Points;
            
            ArraySetAsSeries(m_zigZagTopBuffer, true);
            ArraySetAsSeries(m_zigZagBottomBuffer, true);
            m_zigZagHandler = iCustom(m_symbolCurrency, m_tf, "::Indicators\\Examples\\ZigZagColor",
                                         m_depth, 5, 3
                                        );
            if(m_zigZagHandler == INVALID_HANDLE)
            {
                Print("Không khởi tạo được Zigzag");
                return INIT_FAILED;
            }
            return INIT_SUCCEEDED;
        }
        
        // =======================================================
        void Process(int limit)
        {
            m_infoCurrency.refresh();
            int bars = Bars(m_symbolCurrency, m_tf);
            CopyBuffer(m_zigZagHandler, 0, 0, bars, m_zigZagTopBuffer);
            CopyBuffer(m_zigZagHandler, 1, 0, bars, m_zigZagBottomBuffer);
        }
        
        // =======================================================
        // Phát hiện mô hình cái nêm
        // =======================================================
        bool IsMatched(int limit, int flag)
        {
            
            bool isWedge = IsWedgePattern(m_rise, m_fall);
            if(!isWedge)
            {
                m_rise = m_fall = false;
            }
            return isWedge;
        }
    protected:
        // =======================================================
        // 
        // =======================================================
        bool IsWedgePattern(bool &rise, bool &fall, bool drawLine = true)
        {
            const double accuratePercent = 99;
            double aTop, bTop, aBottom, bBottom;
            
            // =========================================================
            // Tính giá trị a và b của đường xu hướng trên [start]
            // =========================================================
            int rsTopLeft = 0;
            int rsTopRight = 0;
            bool foundTop = false;
            for(int idxR = 1; idxR <= m_period; idxR++)
            {
                if(m_zigZagTopBuffer[idxR] > 0)
                {
                    for(int idxL = m_period; idxL >= 1; idxL--)
                    {
                        if(m_zigZagTopBuffer[idxL] > 0)
                        {
                            if(idxL - idxR >= m_minPeriodOf2Points)
                            {
                                // Tính hệ số a
                                aTop = GetConsA(idxL, m_zigZagTopBuffer[idxL],
                                                        idxR, m_zigZagTopBuffer[idxR]);
                                // Tính hệ số b
                                bTop = GetConsB(idxL, m_zigZagTopBuffer[idxL],
                                                        idxR, m_zigZagTopBuffer[idxR]);
                                                        
                                // Tính tỉ lệ nến nằm dưới đường xu hướng
                                double percent = GetPercentCandlesBelowLine(m_infoCurrency, m_period, aTop, bTop);
                                if( percent >= accuratePercent)
                                {
                                    foundTop = true;
                                    rsTopLeft = idxL;
                                    rsTopRight = idxR;
                                    break;
                                }
                            }
                        }
                    }
                    if(foundTop)
                        break;
                }
                
            }
            // =========================================================
            // Tính giá trị a và b của đường xu hướng trên [ end ]
            // =========================================================
            
            // =========================================================
            // Tính giá trị a và b của đường xu hướng dưới [start]
            // =========================================================
            int rsBottomLeft = 0;
            int rsBottomRight = 0;
            bool foundBottom = false;
            
            for(int idxR = 1; idxR <= m_period; idxR++)
            {
                if(m_zigZagBottomBuffer[idxR] > 0)
                {
                    for(int idxL = m_period; idxL >= 1; idxL--)
                    {
                        if(m_zigZagBottomBuffer[idxL] > 0)
                        {
                            if(idxL - idxR >= m_minPeriodOf2Points)
                            {
                                // Tính hệ số a
                                aBottom = GetConsA(idxL, m_zigZagBottomBuffer[idxL],
                                                        idxR, m_zigZagBottomBuffer[idxR]);
                                // Tính hệ số b
                                bBottom = GetConsB(idxL, m_zigZagBottomBuffer[idxL],
                                                        idxR, m_zigZagBottomBuffer[idxR]);

                                // Tính tỉ lệ nến nằm trên đường xu hướng
                                double percent = GetPercentCandlesAboveLine(m_infoCurrency, m_period, aBottom, bBottom);
                                if( percent >= accuratePercent)
                                {
                                    foundBottom = true;
                                    rsBottomLeft = idxL;
                                    rsBottomRight = idxR;
                                    break;
                                }
                            }
                        }
                    }
                    if(foundBottom)
                        break;
                }
                
            }
            // =========================================================
            // Tính giá trị a và b của đường xu hướng dưới [ end ]
            // =========================================================
            
            // =========================================================
            // Khi đã tìm được 2 đường xu hướng phù hợp:
            // . Kiểm tra có phải phù hợp với mô hình cái nêm
            // . Nếu là mô hình cái nêm thì kiểm tra cái nêm tăng/giảm
            // =========================================================
            if(foundTop && foundBottom)
            {
                // Find the crossing point of top and bottom line
                
                if(aTop - aBottom == 0)
                    return false;
                double crossXIdx = (bBottom - bTop)/(aTop - aBottom);
                double crossYPrice = aTop * crossXIdx + bTop;
                
                int aTopPoints = PriceShiftToPoints(m_symbolCurrency, aTop);
                int aBottomPoints = PriceShiftToPoints(m_symbolCurrency, aBottom);
                
                if(crossXIdx < 0 && MathAbs(crossXIdx) <= m_maxCandleFromCrossPoint)
                {
                    // --------------------------------------
                    // Kiểm tra: đây là mô hình cái nêm giảm
                    if(aTop > 0 && aBottom > 0)
                    {
                        m_fall = true;
                        m_rise = false;
                    }
                    // --------------------------------------
                    // Kiểm tra: đây là mô hình cái nêm tăng
                    if(aTop < 0 && aBottom < 0)
                    {
                        m_rise = true;
                        m_fall = false;
                    }
                    
                    // --------------------------------------
                    // Vẽ 2 đường xu hướng
                    // --------------------------------------
                    if(wedgeLastTopLeftIdx != rsTopLeft || wedgeLastTopRightIdx != rsTopRight
                        || wedgeLastBottomLeftIdx != rsBottomLeft || wedgeLastBottomRightIdx != rsBottomRight)
                    {       
                        wedgeLastTopLeftIdx = rsTopLeft;
                        wedgeLastTopRightIdx = rsTopRight;
                    
                        wedgeLastBottomLeftIdx = rsBottomLeft;
                        wedgeLastBottomRightIdx = rsBottomRight;
                    
                        if(drawLine)
                        {
                            if(m_lineTop != NULL)
                                m_lineTop.Delete();
                            if(m_lineBottom != NULL)
                                m_lineBottom.Delete();
                            
                            datetime date1 = m_infoCurrency.time(rsTopLeft);
                            datetime date2 = m_infoCurrency.time(rsTopRight);
                            m_lineTop = new CChartObjectTrend();
                            m_lineTop.Create(0, "xxxx" + lineId++, 0, date1, m_zigZagTopBuffer[rsTopLeft],
                                        date2, m_zigZagTopBuffer[rsTopRight]);
                            m_lineTop.Color(clrYellow);
                            m_lineTop.RayRight(true);
                            
                            date1 = m_infoCurrency.time(rsBottomLeft);
                            date2 = m_infoCurrency.time(rsBottomRight);
                            m_lineBottom = new CChartObjectTrend();
                            m_lineBottom.Create(0, "xxxx1" + lineId++, 0, date1, m_zigZagBottomBuffer[rsBottomLeft],
                                        date2, m_zigZagBottomBuffer[rsBottomRight]);
                            m_lineBottom.Color(clrWhite);
                            m_lineBottom.RayRight(true);
                        }
                    }
                    return true;
                }
                
                
            }
                
            return false;
        }
};