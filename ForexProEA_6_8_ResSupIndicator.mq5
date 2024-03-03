//+--------------------------------------------------------------------------+
//|                                           ForexProEA_6_6_MultipleSMA.mq5 |
//|                                                             Forex Pro EA |
//|                              https://www.facebook.com/groups/forexproea/ |
//+--------------------------------------------------------------------------+
#property copyright "Forex Pro EA"
#property link      "https://www.facebook.com/groups/forexproea/"
#property version   "1.00"
#property description "Resistance and support zone"

#include "libs\\Common.mqh"
#include "libs\\Graph.mqh"
#include "libs\\File.mqh"

class CZoneEdit;
#include "libs\\UI\\BaseDialog.mqh"

#include <Generic\ArrayList.mqh>
#include <Controls\Button.mqh>
// Khai báo sử dụng chỉ báo chung với biểu đồ chính
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 0

// -----------------------------------------------
// Chỉ báo tín hiệu 
#property indicator_label1  "Resistance upper"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrRed
#property indicator_width1  5
#property indicator_label2  "Resistance lower"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrBlue
#property indicator_width2  5

#property indicator_label3  "Support upper"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrRed
#property indicator_width3  5
#property indicator_label4  "Support lower"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrRed
#property indicator_width4  5

#resource "\\Indicators\\Examples\\ZigZagColor.ex5"
//--------------------------------------------------------------
// Tham số đầu vào (input)
//--------------------------------------------------------------
input int InpDepth = 8;                    // Depth
input int InpZone = 300;                    // Zone (in points)
input int InpLookbackPoint = 10;            // Look back top/bottom points
input color InpResColor = clrDarkGoldenrod; // Color of resistance zone
input color InpSupColor = clrDarkSeaGreen;  // Color of support zone
input color InpTurningColor = clrPurple;    // Color of turning res <-> sup
input color InpSingleColor = clrDarkSlateGray;       // Color of single top/bottom point
input bool  InpShowZoneSingleTopBottom = false;       // Show zone of single top/bottom point
input bool InpUseDialogZoneEdit = false;   // Show dialog to edit zone
input int InpStepEditZone = 5;          // |- Step of each +/-
//--------------------------------------------------------------
//const int MAX_POINT = 10;

double m_resUpperBuffer[], m_resLowerBuffer[], m_supUpperBuffer[], m_supLowerBuffer[],
       m_zigzagTopBuffer[], m_zigzagBottomBuffer[];
int m_zigzagHandler;

CChartObjectTrend *m_line[];
CChartObjectRectangle *m_rec[];

//template void (*TActZone)(CZoneEdit &);
//template<typename T>
//typedef void (*TActionGeneric)(CZoneEdit &);

template<typename X>;
class CZoneEdit: public CBaseDialog
{
    private:
        CBaseDialog m_dlg;
        CLabel *m_lblZoneStatus;
    public:
        TAction ZoneUpAction, ZoneDownAction;
        void Destroy(const int reason = 0)
        {
            m_dlg.Destroy(reason);
        }
        int Left() {return m_dlg.Left();}
        int Top() {return m_dlg.Top();}
        void ProcessEvent(const int id,       // event id
                const long&   lparam, // chart period
                const double& dparam, // price
                const string& sparam  // symbol
               )
        {
            m_dlg.ProcessEvent(id,lparam,dparam,sparam);
        }
        
        bool Init(TAction &zoneUp, TAction &zoneDown, int x, int y)
        {
            //int x = 20, y = 40;
            if(!m_dlg.Create(0, "dlgSetting", 0, x, y, x + 150, y+230))
            {
                Print("Cannot init dialog");
                return false;
            }
            m_dlg.Caption("Res/Sup - Zone");
            TAction actUp = zoneUp;
            TAction actDown = zoneDown;
            CButton *btnUp, *btnDown;
            m_dlg.AddButton(btnUp, "Zone +", actUp, 20, 60, 100, 60, StringToColor("215,92,93"));
            m_dlg.AddButton(btnDown, "Zone -", actDown, 20, 120, 100, 60, StringToColor("38,166,154"));
            m_dlg.AddLabel(m_lblZoneStatus, "Zone = "+ (string)m_dynamicZone, 20, 20);
            m_dlg.Run();

            return true;
        }
        void UpdateZoneStatus()
        {
            if(m_lblZoneStatus != NULL)
                m_lblZoneStatus.Text("Zone = "+ (string)m_dynamicZone);
        }
};
//void Event_ZoneUp(CZoneEdit &parent)
//{
//    
//}
//void Event_ZoneDown(CZoneEdit &parent)
//{
//    
//}
CZoneEdit *m_zoneEditGUI;
int m_dynamicZone;
//+------------------------------------------------------------------+
//| Sự kiện khởi tạo
//+------------------------------------------------------------------+
int OnInit()
{
    InitSeries(m_zigzagTopBuffer);
    InitSeries(m_zigzagBottomBuffer);
    //InitSeries(m_resUpperBuffer);
    //InitSeries(m_resLowerBuffer);
    //InitSeries(m_supUpperBuffer);
    //InitSeries(m_supLowerBuffer);
    
    // Thiết lập hiển thị chính xác số thập phân
    IndicatorSetInteger(INDICATOR_DIGITS, _Digits + 1);
    
    // Thiết lập bộ đệm cho chỉ báo tín hiệu
    SetIndexBuffer(0, m_zigzagTopBuffer, INDICATOR_CALCULATIONS);
    SetIndexBuffer(1, m_zigzagBottomBuffer, INDICATOR_CALCULATIONS);
    //SetIndexBuffer(2, m_resUpperBuffer, INDICATOR_DATA);
    //SetIndexBuffer(3, m_resLowerBuffer, INDICATOR_DATA);
    //SetIndexBuffer(4, m_supUpperBuffer, INDICATOR_DATA);
    //SetIndexBuffer(5, m_supLowerBuffer, INDICATOR_DATA);
    
    // Với những vị trí không có giá trị, thiết lập giá trị 0.0
    //PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, 0.0);
    //PlotIndexSetDouble(3, PLOT_EMPTY_VALUE, 0.0);
    //PlotIndexSetDouble(4, PLOT_EMPTY_VALUE, 0.0);
    //PlotIndexSetDouble(5, PLOT_EMPTY_VALUE, 0.0);
    
    // Thiết lập kiểu vẽ của đường chỉ báo tín hiệu BUY/SELL
    // Giá trị code 159 theo font Wingdings là kiểu vẽ vòng tròn
    //PlotIndexSetInteger(2, PLOT_ARROW, 159);
    //PlotIndexSetInteger(3, PLOT_ARROW, 159);
    //PlotIndexSetInteger(4, PLOT_ARROW, 159);
    //PlotIndexSetInteger(5, PLOT_ARROW, 159);
    
    m_dynamicZone = InpZone;
    int x = 20, y = 40;
    LoadConfig(m_dynamicZone, x, y);
    
    m_zigzagHandler = iCustom(NULL, 0, "::Indicators\\Examples\\ZigZagColor",
                              InpDepth,5,3);
    
    if(m_zigzagHandler <= 0)
    {
        Print("Cannot initalize zigzag");
        return INIT_FAILED;
    }

    ArrayResize(m_line, InpLookbackPoint * 2);
    ArrayResize(m_rec, InpLookbackPoint * 2);
    
    ClearAllGraph();
    
    if(InpUseDialogZoneEdit)
    {
        m_zoneEditGUI = new CZoneEdit();
        TAction actUp = ZoneUp;
        TAction actDown = ZoneDown;
        if(!m_zoneEditGUI.Init(actUp, actDown, x, y))
            return INIT_FAILED;
    }
    
    //LoadConfig();
    return(INIT_SUCCEEDED);
}
void ZoneUp()
{
    m_dynamicZone += InpStepEditZone;
    //Print("Zone=" + (string)m_dynamicZone);
    m_zoneEditGUI.UpdateZoneStatus();
}
void ZoneDown()
{
    if(m_dynamicZone - InpStepEditZone <= 0)
        return;
    m_dynamicZone -= InpStepEditZone;
    //Print("Zone=" + (string)m_dynamicZone);
    
    m_zoneEditGUI.UpdateZoneStatus();
}

//+------------------------------------------------------------------+
//| Sự kiện được gọi mỗi khi có tín hiệu từ server                            |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    // ----------------------------------------------------
    // Tính toán các giá trị cho chỉ báo zigzag
    int calculated = BarsCalculated(m_zigzagHandler);
    if(calculated < rates_total)
    {
        //Print("Not all data of zigzag is calculated (", calculated," bars). Error ", GetLastError());
        return(0);
    }
    
    int to_copy;
    // Thời điểm khởi đầu -> Copy hết dữ liệu
    if(prev_calculated > rates_total || prev_calculated <= 0)
    {
        to_copy = rates_total;
    }
    // Từ lần thứ 2 trở đi
    else
    {
        to_copy = rates_total - prev_calculated;
        if(prev_calculated > 0)
            to_copy++;
    }
    
    if(to_copy == 0)
        return rates_total;
    

    // Zigzag
    if(IsStopped()) // checking for stop flag
        return(0);
    if(CopyBuffer(m_zigzagHandler, 0, 0, to_copy, m_zigzagTopBuffer) <= 0)
    {
        Print("Getting zigzag top is failed! Error ", GetLastError());
        return(0);
    }
    if(CopyBuffer(m_zigzagHandler, 1, 0, to_copy, m_zigzagBottomBuffer) <= 0)
    {
        Print("Getting zigzag bottom is failed! Error ", GetLastError());
        return(0);
    }
    
    ProcessShowResSup(rates_total, prev_calculated, time, open, high, low, close);
    return rates_total;
}
void ProcessShowResSup(const int rates_total,
                       const int prev_calculated,
                       const datetime &time[],
                       const double &open[],
                       const double &high[],
                       const double &low[],
                       const double &close[])
{
    CArrayList<int> points;
    int idxFindTop = 4;
    int idxFindBottom = 4;
    for(int idx = 0; idx < InpLookbackPoint; idx++)
    {
        idxFindTop = GetFirstPoint(m_zigzagTopBuffer, idxFindTop + 1);
        idxFindBottom = GetFirstPoint(m_zigzagBottomBuffer, idxFindBottom + 1);
        points.Add(idxFindTop);
        points.Add(idxFindBottom);
    }
    points.Sort();
    CArrayList<int> excludePoints;
    double zone = PointsToPriceShift(_Symbol, m_dynamicZone);
    
    datetime time1 = NULL;
    
    // Loop 0
    for(int idx = points.Count() - 1; idx > 0; idx--)
    {
        bool currPointTop = false, currPointBottom = false;
        bool drawRec = false;
        int posCandle;
        points.TryGetValue(idx, posCandle);
        if(excludePoints.IndexOf(posCandle) >= 0)
        {
            if(ObjectFind(0, "rec_" + (string)idx) >= 0)
            {
                ObjectDelete(0, "rec_" + (string)idx);
                m_rec[idx] = NULL;
            }
            continue;
        }
        // ----------------------------------------
        // Vị trí x1: time1
        if(time1 > time[rates_total - posCandle - 1] || time1 == NULL)
        {
            time1 = time[rates_total - posCandle - 1];
            time1 -= PeriodSeconds(PERIOD_CURRENT)*5;
        }
        
        // ----------------------------------------
        // Vị trí x2: time2
        datetime time2 = time[rates_total - 1];
        double maxPrice = -1, minPrice = -1;
        time2 += PeriodSeconds(PERIOD_CURRENT)*5;
        
        double price = m_zigzagTopBuffer[posCandle];
        if(price == 0)
            price = m_zigzagBottomBuffer[posCandle];
        
        // ----------------------------------------
        // Vị trí y1: maxPrice
        // Vị trí y2: minPrice
        if(maxPrice == -1 || maxPrice < price)
            maxPrice = price;
        if(minPrice == -1 || minPrice > price)
            minPrice = price;
            
        if(m_zigzagTopBuffer[posCandle] > 0)
            currPointTop = true;
        if(m_zigzagBottomBuffer[posCandle] > 0)
            currPointBottom = true;
        
        //if(posCandle == 44 || posCandle == 104)
        //    Print(posCandle + "; top=" + m_zigzagTopBuffer[posCandle] + "; bottom=" + m_zigzagBottomBuffer[posCandle]);
        
        // Từ top/bottom hiện tại, duyệt các point kế tiếp để tìm ra các điểm nằm trong zone
        bool foundPointTop = false, foundPointBottom = false;
        // Loop check
        for(int idxCheck = idx - 1; idxCheck >= 0; idxCheck--)
        {
            int posCandle1;
            points.TryGetValue(idxCheck, posCandle1);
            
            double price1 = m_zigzagTopBuffer[posCandle1];
            if(price1 == 0)
                price1 = m_zigzagBottomBuffer[posCandle1];
            
            double delta = MathAbs(price - price1);
            //if(posCandle == 104 && posCandle1 == 44)
            //    Print(posCandle + ";zone=" + zone + "; delta=" + delta + "; top=" + m_zigzagTopBuffer[posCandle] + "; top2=" + m_zigzagTopBuffer[posCandle1]);
        
            if(delta <= zone)
            {
                //if(posCandle == 104 && posCandle1 == 44)
                //    Print("Found");
                if(maxPrice == -1 || maxPrice < price1)
                    maxPrice = price1;
                if(minPrice == -1 || minPrice > price1)
                    minPrice = price1;
                if(excludePoints.IndexOf(posCandle1) < 0)
                {
                    if(m_zigzagTopBuffer[posCandle1] > 0)
                        foundPointTop = true;
                    if(m_zigzagBottomBuffer[posCandle1] > 0)
                        foundPointBottom = true;
                    excludePoints.Add(posCandle1);
                    drawRec = true;
                }
            }
        } // End Loop check
        
        if(drawRec)
        {
            color clr = clrDarkSeaGreen;
            // Turning
            if((currPointTop && foundPointBottom) || (currPointBottom && foundPointTop))
                clr = InpTurningColor;
            // Resistance
            else if(currPointTop && foundPointTop)
                clr = InpResColor;
            // Support
            else if(currPointBottom && foundPointBottom)
                clr = InpSupColor;
            
            DrawRec(m_rec[idx], "rec_" + (string)idx, 
                    time1, maxPrice,
                    time2, minPrice,
                    clr);
        }
        else
        {
            if(InpShowZoneSingleTopBottom)
            {
                if(excludePoints.IndexOf(posCandle) < 0)
                {
                    double price2 = 0;
                    if(m_zigzagTopBuffer[posCandle] > 0)
                    {
                        price2 = open[rates_total - posCandle - 1];
                        if(close[rates_total - posCandle - 1] > open[rates_total - posCandle - 1])
                            price2 = close[rates_total - posCandle - 1];
                        if(high[rates_total - posCandle - 2] > price2)
                            price2 = high[rates_total - posCandle - 2];
                        if(high[rates_total - posCandle] > price2)
                            price2 = high[rates_total - posCandle];
                    }
                    if(m_zigzagBottomBuffer[posCandle] > 0)
                    {
                        price2 = open[rates_total - posCandle - 1];
                        if(close[rates_total - posCandle - 1] < open[rates_total - posCandle - 1])
                            price2 = close[rates_total - posCandle - 1];
                        if(low[rates_total - posCandle - 2] < price2)
                            price2 = low[rates_total - posCandle - 2];
                        if(low[rates_total - posCandle] < price2)
                            price2 = low[rates_total - posCandle];
                    }
                    
                    // ------------------------------------------------
                    // Check overlap
                    bool isOverlap = false;
                    for(int idxOverlap = 0; idxOverlap < ArraySize(m_rec); idxOverlap++)
                    {
                        if(ObjectFind(0, "rec_" + (string)idxOverlap) >= 0
                           && ("rec_" + (string)idx) != ("rec_" + (string)idxOverlap))
                        {
                            
                            double anchorPriceH = ObjectGetDouble(0, "rec_" + (string)idxOverlap, OBJPROP_PRICE, 0);
                            double anchorPriceL = ObjectGetDouble(0, "rec_" + (string)idxOverlap, OBJPROP_PRICE, 1);
                            if(anchorPriceH < anchorPriceL)
                            {
                                double temp = anchorPriceH;
                                anchorPriceH = anchorPriceL;
                                anchorPriceL = temp;
                            }
                            //Print("0=" + anchorPrice1 + "; 1=" + anchorPrice2);
                            if(anchorPriceH >= price && anchorPriceL <= price)
                                isOverlap = true;
                            if(anchorPriceH >= price2 && anchorPriceL <= price2)
                                isOverlap = true;
                            if((anchorPriceH < price && anchorPriceL > price2) 
                               ||(anchorPriceH < price2 && anchorPriceL > price))
                               isOverlap = true;
                        }
                        if(isOverlap)
                            break;
                    }
                    
                    // ------------------------------------------------
                    if(!isOverlap)
                    {
                        DrawRec(m_rec[idx], "rec_" + (string)idx, 
                                        time1, price,
                                        time2, price2, InpSingleColor);
                    }
                    else
                    {
                        // Xóa rec không sử dụng
                        if(ObjectFind(0, "rec_" + (string)idx) >= 0)
                        {
                            ObjectDelete(0, "rec_" + (string)idx);
                            m_rec[idx] = NULL;
                        }
                    }
                }
                else
                {
                    // Xóa rec không sử dụng
                    if(ObjectFind(0, "rec_" + (string)idx) >= 0)
                    {
                        ObjectDelete(0, "rec_" + (string)idx);
                        m_rec[idx] = NULL;
                    }
                }
            }
            else
            {
                // Xóa rec không sử dụng
                if(ObjectFind(0, "rec_" + (string)idx) >= 0)
                {
                    ObjectDelete(0, "rec_" + (string)idx);
                    m_rec[idx] = NULL;
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Sự kiện trên biểu đồ
//+------------------------------------------------------------------+
void OnChartEvent(const int id,       // event id
                const long&   lparam, // chart period
                const double& dparam, // price
                const string& sparam  // symbol
               )
{
    
    // Xử lý sự kiện cho các controls
    if(InpUseDialogZoneEdit && m_zoneEditGUI != NULL)
    {
        m_zoneEditGUI.ProcessEvent(id,lparam,dparam,sparam);
    }
    
}

void OnDeinit(const int reason)
{
    // Save zone value
    SaveConfig();
    
    if(InpUseDialogZoneEdit && m_zoneEditGUI != NULL)
        m_zoneEditGUI.Destroy(reason);
    //ClearAllGraph();
    m_zoneEditGUI = NULL;
    //ChartRedraw();
    //Print("BYE BYE BYE");
    
    
}
void SaveConfig()
{
    string configFile = "ressup\\zone_" + _Symbol + "_" + _Period + ".ini";
    string content = (string)m_dynamicZone;
    WriteFile(configFile, content);
    
    configFile = "ressup\\dialog_" + _Symbol + ".ini";
    content = m_zoneEditGUI.Left() + ";" + m_zoneEditGUI.Top();
    WriteFile(configFile, content);
}

void LoadConfig(int &dynamicZone, int &x1, int &y1)
{
    string configFile = "ressup\\zone_" + _Symbol + "_" + _Period + ".ini";
    string content = "";
    if(FileIsExist(configFile, FILE_COMMON))
    {
        content = ReadFile(configFile);
        if(content != "")
        {
            int zone = (int)StringToInteger(content);
            if(zone > 0)
            {
                dynamicZone = zone;
            }
        }
    }
    
    configFile = "ressup\\dialog_" + _Symbol + ".ini";
    content = "";
    if(FileIsExist(configFile, FILE_COMMON))
    {
        content = ReadFile(configFile);
        if(content != "")
        {
            int zone = (int)StringToInteger(content);
            if(zone > 0)
            {
                string segs[];
                Split(content, ";", segs);
                if(ArraySize(segs) >= 2)
                {
                    x1 = StringToInteger(segs[0]);
                    y1 = StringToInteger(segs[1]);
                }
            }
        }
    }
}
void ClearAllGraph()
{
    int len = ArraySize(m_rec);
    for(int i = 0; i < len; i++)
    {
        if(m_rec[i] != NULL && ObjectFind(0, "rec_" + (string)i) >= 0)
            ObjectDelete(0, "rec_" + (string)i);
        m_rec[i] = NULL;
    }
    len = ArraySize(m_line);
    for(int i = 0; i < len; i++)
    {
        if(m_line[i] != NULL && ObjectFind(0, "line_" + (string)i) >= 0)
            ObjectDelete(0, "line_" + (string)i);
        m_line[i] = NULL;
    }
    ChartRedraw();
    //Print("Clear all graph");
}