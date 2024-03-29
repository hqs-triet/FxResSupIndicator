#include <Trade\PositionInfo.mqh>
#include  "..\ExpertWrapper.mqh"
#include  "..\Common.mqh"
#include  "..\CLineH.mqh"
#include  "..\BuySellDialog.mqh"
#include "..\\File.mqh"

const string CONST_ENTRY_ID = "entry001";
const string CONST_ENTRY_TEXT = "Entry";
const string CONST_SL_ID = "sl001";
const string CONST_SL_TEXT = "SL";
const string CONST_TP_ID = "tp001";
const string CONST_TP_TEXT = "TP";
const string CONST_TRIGGER_ID = "trig001";
const string CONST_TRIGGER_TEXT = "Trigger";



class CGuiTrade
{
    private:
        string m_symbolCurrency;
        CTrade m_trader;
        AllSeriesInfo m_infoCurrency;
        ENUM_TIMEFRAMES m_tf;
        
        CLineH *m_lineEntry, *m_lineSL, *m_lineTP, *m_lineTrigger;
        CControlsDialog *ExtDialog;
        
        TAction m_actionSell, m_actionBuy, m_actOnUseGUI, m_actOnUseStopLimit;
    public:
        bool ExistEntryLine()
        {
            return m_lineEntry.ExistObject();
        }
        double Entry()
        {
            if(ExistEntryLine())
                return m_lineEntry.Price();
            return 0;
        }
        bool ExistSLLine()
        {   
            return m_lineSL.ExistObject();
        }
        double SL()
        {
            if(ExistSLLine())
                return m_lineSL.Price();
            return 0;
        }
        bool ExistTPLine()
        {
            return m_lineTP.ExistObject();
        }
        double TP()
        {
            if(ExistTPLine())
                return m_lineTP.Price();
            return 0;
        }
        bool ExistTriggerLine()
        {
            return m_lineTrigger.ExistObject();
        }
        double Trigger()
        {
            if(ExistTriggerLine())
                return m_lineTrigger.Price();
            return 0;
        }
        void CanSell(bool v)
        {
            ExtDialog.CanSell(v);
        }
        void CanBuy(bool v)
        {
            ExtDialog.CanBuy(v);
        }
        void OnSell(TAction act)
        {
            m_actionSell = act;
        }
        void OnBuy(TAction act)
        {
            m_actionBuy = act;
        }
        double Risk()
        {
            return ExtDialog.Risk();
        }
        void Risk(double r)
        {
            ExtDialog.Risk(r);
        }
        bool UseRiskByPercent()
        {
            return ExtDialog.UseRiskByPercent();
        }
        bool UseRiskByMoney()
        {
            return ExtDialog.UseRiskByMoney();
        }
        double Money()
        {
            return ExtDialog.Money();
        }
        void SetActionUseGUI(TAction act)
        {
            m_actOnUseGUI = act;
        }
        void SetActionUseStopLimit(TAction act)
        {
            m_actOnUseStopLimit = act;
        }
        void Destroy(int reason)
        {
            ExtDialog.Destroy(reason);
        }
        bool Init(string symbol, ENUM_TIMEFRAMES tf, 
                  CTrade &trader, AllSeriesInfo &infoCurrency)
        {
            m_symbolCurrency = symbol;
            m_tf = tf;
            m_trader = trader;
            m_infoCurrency = infoCurrency;
            
            // Khởi tạo các đối tượng đồ trên biểu đồ
            if(m_lineEntry == NULL)
                m_lineEntry = new CLineH();
            //else
            //    m_lineEntry.Probe(CONST_ENTRY_ID);
            m_lineEntry.Probe(CONST_ENTRY_ID);
            
            if(m_lineSL == NULL)
                m_lineSL = new CLineH();
            //else
            //    m_lineSL.Probe(CONST_SL_ID);
            m_lineSL.Probe(CONST_SL_ID);
        
            if(m_lineTP == NULL)
                m_lineTP = new CLineH();
            //else
            //    m_lineTP.Probe(CONST_TP_ID);
            m_lineTP.Probe(CONST_TP_ID);
            
            if(m_lineTrigger == NULL)
                m_lineTrigger = new CLineH();
            m_lineTrigger.Probe(CONST_TRIGGER_ID);
                
            // ===================================================================
            // Khởi tạo bảng điều khiển
            // ===================================================================
            bool canDraw, useStopLimit;
            int x1 = 20, y1 = 20;
            LoadConfig(canDraw, x1, y1, useStopLimit);
            
            ExtDialog = new CControlsDialog();
            int w = 360, h = 400;
            
            int x2 = x1 + w, y2 = y1 + h;
            if(!ExtDialog.Create(0,"ForexProEA - Trading Tool 1.0",0, 
                                 x1, y1, x2, y2))
                return(false);
            ExtDialog.SetActionButtonSell(m_actionSell);
            ExtDialog.SetActionButtonBuy(m_actionBuy);
            ExtDialog.SetActionUseGUI(m_actOnUseGUI);
            ExtDialog.SetActionUseStopLimit(m_actOnUseStopLimit);
            ExtDialog.CanDraw(canDraw);
            ExtDialog.UseStopLimit(useStopLimit);
            ExtDialog.Run();
            // ===================================================================
            
            
            return true;
        }
        void OnUseStopLimit()
        {
            if(m_lineTrigger != NULL && ExtDialog != NULL)
                if(!ExtDialog.CanDraw() || !ExtDialog.UseStopLimit())
                    m_lineTrigger.Remove();
        }
        void OnUseGUI()
        {
            if(m_lineEntry != NULL && ExtDialog != NULL)
                if(!ExtDialog.CanDraw())
                    m_lineEntry.Remove();
            
            if(m_lineSL != NULL && ExtDialog != NULL)
                if(!ExtDialog.CanDraw())
                    m_lineSL.Remove();
            
            if(m_lineTP != NULL && ExtDialog != NULL)
                if(!ExtDialog.CanDraw())
                    m_lineTP.Remove();
            
            if(m_lineTrigger != NULL && ExtDialog != NULL)
                if(!ExtDialog.CanDraw() || !ExtDialog.UseStopLimit())
                    m_lineTrigger.Remove();
        }
        void ClearLines()
        {
            if(m_lineEntry != NULL && ExtDialog != NULL)
                m_lineEntry.Remove();
            if(m_lineSL != NULL && ExtDialog != NULL)
                m_lineSL.Remove();
            if(m_lineTP != NULL && ExtDialog != NULL)
                m_lineTP.Remove();
            if(m_lineTrigger != NULL && ExtDialog != NULL)
                m_lineTrigger.Remove();
        }
        void Process(int limit)
        {
        
        }
        void ReleaseObject(const int reason)
        {
            SaveConfig();
            // Hủy đối tượng: bảng điều khiển
            if(ExtDialog != NULL)
                ExtDialog.Destroy(reason);
        }
        
        void ProcessChartEvent(const int id,       // event id
                                const long&   lparam, // chart period
                                const double& dparam, // price
                                const string& sparam  // symbol
                               )
        {
            // Xử lý sự kiện cho các controls
            ExtDialog.ProcessEvent(id,lparam,dparam,sparam);
            m_lineTrigger.ProcessEvent(id, lparam, dparam, sparam);
            m_lineEntry.ProcessEvent(id, lparam, dparam, sparam);
            m_lineSL.ProcessEvent(id, lparam, dparam, sparam);
            m_lineTP.ProcessEvent(id, lparam, dparam, sparam);
            
            
            // Tính toán khối lượng lệnh giao dịch
            CalculateVol();
            
            // Tính toán tỉ lệ lợi nhuận
            if(m_lineEntry.ExistObject() && m_lineSL.ExistObject() && m_lineTP.ExistObject())
            {
                ExtDialog.RR(m_lineEntry.Price(), m_lineSL.Price(), m_lineTP.Price());
            }
            
            // Hiển thị Entry, SL, TP với ngữ cảnh phù hợp
            if(id == CHARTEVENT_CLICK && !ExtDialog.MouseInsideDialog())
            {
                datetime time;
                double price;
                int subwindow;
                ChartXYToTimePrice(0,lparam,dparam,subwindow,time,price);
                if(ExtDialog.CanDraw())
                {
                    bool rs = ExtDialog.UseStopLimit();
                    rs &= m_lineTrigger.ExistObject();
                    if(ExtDialog.UseStopLimit() && m_lineTrigger != NULL && !m_lineTrigger.ExistObject())
                        m_lineTrigger.Init(CONST_TRIGGER_ID, CONST_TRIGGER_TEXT, price, time, clrGray);

                    else if(m_lineEntry != NULL && !m_lineEntry.ExistObject())
                        m_lineEntry.Init(CONST_ENTRY_ID, CONST_ENTRY_TEXT, price, time);
                    else if(m_lineSL != NULL && m_lineEntry.ExistObject() && !m_lineSL.ExistObject())
                        m_lineSL.Init(CONST_SL_ID, CONST_SL_TEXT, price, time, clrRed);
                    else if(m_lineTP != NULL && m_lineEntry.ExistObject() && m_lineSL.ExistObject() && !m_lineTP.ExistObject())
                        m_lineTP.Init(CONST_TP_ID, CONST_TP_TEXT, price, time, clrGreen);
                }
            }
            
            // Kiểm tra điều kiện cho phép BUY/SELL
            bool canSell = true;
            bool canBuy = true;
            
            if(m_lineEntry != NULL && m_lineEntry.ExistObject() && 
                   m_lineSL != NULL && m_lineSL.ExistObject() && 
                   m_lineTP != NULL && m_lineTP.ExistObject())
            {
                canBuy &= m_lineEntry.Price() > m_lineSL.Price() &&
                          m_lineEntry.Price() < m_lineTP.Price();
                canSell &= m_lineEntry.Price() < m_lineSL.Price() &&
                                 m_lineEntry.Price() > m_lineTP.Price();
            }
            else {
                canBuy = canSell = false;
            }
            
            if(m_lineTrigger != NULL && m_lineTrigger.ExistObject()) {
                double priceShiftSpread = PointsToPriceShift(m_symbolCurrency, m_infoCurrency.symbol_info().Spread());
                canBuy &= m_lineTrigger.Price() > m_infoCurrency.ask() + priceShiftSpread;
                canSell &= m_lineTrigger.Price() < m_infoCurrency.bid() - priceShiftSpread;
                
                if(canSell) {
                    canSell &= m_lineEntry.Price() > m_lineTrigger.Price();
                }
                if(canBuy) {
                    canBuy &= m_lineEntry.Price() < m_lineTrigger.Price();
                }
            }
            
            ExtDialog.CanBuy(canBuy);
            ExtDialog.CanSell(canSell);
            
        }
    protected:
        void SaveConfig()
        {
            string configFile = "guitrade\\checkbox_" + _Symbol + ".ini";
            string content = ExtDialog.CanDraw() ? "1": "0";
            content += ";" + (ExtDialog.UseStopLimit() ? "1": "0");
            WriteFile(configFile, content);
            
            configFile = "guitrade\\dialog_" + _Symbol + ".ini";
            int x1, y1;
            ExtDialog.getPosition(x1, y1);
            content = IntegerToString(x1) + ";" + IntegerToString(y1);
            WriteFile(configFile, content);
        }
        void LoadConfig(bool &canDraw, int &x1, int &y1, bool &useStopLimit)
        {
            string configFile = "guitrade\\checkbox_" + _Symbol + ".ini";
            string content = "";
            if(FileIsExist(configFile, FILE_COMMON))
            {
                content = ReadFile(configFile);
                
                if(content != "")
                {
                    string segs[];
                    Split(content, ";", segs);
                    if(ArraySize(segs) >= 2) {
                        canDraw = (int)StringToInteger(segs[0]) == 1;
                        useStopLimit = (int)StringToInteger(segs[1]) == 1; 
                    }
                }
            }
            
            content = "";
            configFile = "guitrade\\dialog_" + _Symbol + ".ini";
            if(FileIsExist(configFile, FILE_COMMON))
            {
                content = ReadFile(configFile);
                if(content != "")
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
        //+------------------------------------------------------------------+
        // Cập nhật khối lượng (volume) khi có SL
        //+------------------------------------------------------------------+
        void CalculateVol()
        {
            double entry, sl, tp;
            if(m_lineEntry.ExistObject() && m_lineSL.ExistObject() && m_lineTP.ExistObject())
            {
                entry = m_lineEntry.Price();
                sl = m_lineSL.Price();
                tp = m_lineTP.Price();
            }
            else
            {
                ExtDialog.Volume(0);
                return;
            }
            
            int slPoint = PriceShiftToPoints(m_symbolCurrency, MathAbs(entry - sl));
            double lot = 0;
            if(ExtDialog.UseRiskByMoney())
                lot = MoneyToLots(m_symbolCurrency, ExtDialog.Money(), slPoint);
            else {
                if(ExtDialog.UseRiskByPercent())
                    lot = PointsToLots(m_symbolCurrency, ExtDialog.Risk(), slPoint);
                else
                    lot = ExtDialog.Risk();
            }
                
            double slMoney = PointsToMoney(m_symbolCurrency, slPoint, lot);
            if(ExtDialog.UseRiskByMoney())
                slMoney = ExtDialog.Money();
            double tpMoney = slMoney * ExtDialog.RR();
            if(lot == 0)
            {
                slMoney = tpMoney = 0;
            }
            ExtDialog.Volume(lot);
            ExtDialog.SLMoney(slMoney);
            ExtDialog.TPMoney(tpMoney);
        }
    
};