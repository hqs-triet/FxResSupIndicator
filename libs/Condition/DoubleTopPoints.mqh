
#include <Trade\PositionInfo.mqh>
#include <trade/trade.mqh>
#include  "..\ExpertWrapper.mqh"
#include  "..\Common.mqh"
#include  "ICondition.mqh"
#resource "\\Indicators\\Examples\ZigZagColor.ex5"

// ===================================================================
// Tham số đầu vào [start]
// ===================================================================

// ===================================================================
// Tham số đầu vào [end]
// ===================================================================

// ===================================================================
// Khai báo đối tượng trade ngẫu nhiên, thừa kế IAlgorithm
// ===================================================================
class CDoubleTopPoints: public ICondition
{
    private:
        double m_zigZagTopBuffer[], m_zigZagBottomBuffer[];
        int m_zigZagHandler;
        int m_period, m_zone, m_depth;
        int m_minPeriod2TopPoints;
    public:
        
        int Init(string symbol, ENUM_TIMEFRAMES tf, 
                 AllSeriesInfo &infoCurrency, int zone, int period, int depth, int minPeriod2TopPoints)
        {
            ICondition::Init(symbol, tf, infoCurrency);
            
            m_zone = zone;
            m_period = period;
            m_depth = depth;
            m_minPeriod2TopPoints = minPeriod2TopPoints;
            
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
        // Phát hiện mô hình 2 đỉnh
        // =======================================================
        bool IsMatched(int limit, int flag)
        {
            int idxFirstTopPoint = GetFirstPoint(m_zigZagTopBuffer);
            if(idxFirstTopPoint == 1)
                return false;
                
            int idxSecondTopPoint = GetFirstPoint(m_zigZagTopBuffer, idxFirstTopPoint + 1);
            
            if(idxSecondTopPoint > m_period)
                return false;
            
            int idxFirstBottomPoint = GetFirstPoint(m_zigZagBottomBuffer, 2);
            if(idxFirstBottomPoint < idxFirstTopPoint)
                return false;
            
            if(idxSecondTopPoint - idxFirstTopPoint < m_minPeriod2TopPoints)
                return false;
            
            double zone = PointsToPriceShift(m_symbolCurrency, m_zone);
            if(MathAbs(m_zigZagTopBuffer[idxFirstTopPoint] - m_zigZagTopBuffer[idxSecondTopPoint]) > zone)
                return false;
            
            double neckPrice = NecklinePrice();
            if(m_infoCurrency.close(1) >= neckPrice)
                return false;
                
            return true;
        }
        
        // =======================================================
        // Phát hiện có dấu hiệu mô hình 2 đỉnh
        // =======================================================
        bool HasSignalMatched(int limit, int flag)
        {
            int idxFirstTopPoint = GetFirstPoint(m_zigZagTopBuffer);
            if(idxFirstTopPoint == 1)
                return false;
                
            int idxSecondTopPoint = GetFirstPoint(m_zigZagTopBuffer, idxFirstTopPoint + 1);
            
            if(idxSecondTopPoint > m_period)
                return false;
            
            int idxFirstBottomPoint = GetFirstPoint(m_zigZagBottomBuffer, 2);
            if(idxFirstBottomPoint < idxFirstTopPoint)
                return false;
            
            if(idxSecondTopPoint - idxFirstTopPoint < m_minPeriod2TopPoints)
                return false;
            
            double zone = PointsToPriceShift(m_symbolCurrency, m_zone);
            if(MathAbs(m_zigZagTopBuffer[idxFirstTopPoint] - m_zigZagTopBuffer[idxSecondTopPoint]) > zone)
                return false;
            
            return true;
        }
        
        // =======================================================
        // Giá neckline
        // =======================================================
        double NecklinePrice()
        {
            int idxFirstTopPoint = GetFirstPoint(m_zigZagTopBuffer);
            int idxSecondTopPoint = GetFirstPoint(m_zigZagTopBuffer, idxFirstTopPoint + 1);
            int idxFirstBottomPoint = GetFirstPoint(m_zigZagBottomBuffer, 2);
            if(idxFirstBottomPoint > idxFirstTopPoint 
               && idxFirstBottomPoint < idxSecondTopPoint)
                return m_zigZagBottomBuffer[idxFirstBottomPoint];
            return 0;
        }
        
        // =======================================================
        // Giá cao nhất (đỉnh) của mô hình
        // =======================================================
        double TopPointPrice()
        {
            int idxFirstTopPoint = GetFirstPoint(m_zigZagTopBuffer);
            int idxSecondTopPoint = GetFirstPoint(m_zigZagTopBuffer, idxFirstTopPoint + 1);
            int idxFirstBottomPoint = GetFirstPoint(m_zigZagBottomBuffer, 2);
            if(idxFirstBottomPoint > idxFirstTopPoint 
               && idxFirstBottomPoint < idxSecondTopPoint)
            {
                if(m_zigZagTopBuffer[idxFirstTopPoint] > m_zigZagTopBuffer[idxSecondTopPoint])
                    return m_zigZagTopBuffer[idxFirstTopPoint];
                else
                    return m_zigZagTopBuffer[idxSecondTopPoint];
            }
            return 0;
        }
};