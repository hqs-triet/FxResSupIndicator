//+------------------------------------------------------------------+
//|                                               ControlsDialog.mqh |
//|                   Copyright 2009-2017, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Edit.mqh>
#include <Controls\DatePicker.mqh>
#include <Controls\ListView.mqh>
#include <Controls\ComboBox.mqh>
#include <Controls\SpinEdit.mqh>
#include <Controls\RadioGroup.mqh>
#include <Controls\CheckBox.mqh>
#include <Controls\CheckGroup.mqh>
#include <Controls\Label.mqh>
#include  "..\libs\Action.mqh"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
//--- indents and gaps
#define INDENT_LEFT                         (11)      // indent from left (with allowance for border width)
#define INDENT_TOP                          (11)      // indent from top (with allowance for border width)
#define INDENT_RIGHT                        (11)      // indent from right (with allowance for border width)
#define INDENT_BOTTOM                       (11)      // indent from bottom (with allowance for border width)
#define CONTROLS_GAP_X                      (5)       // gap by X coordinate
#define CONTROLS_GAP_Y                      (5)       // gap by Y coordinate
//--- for buttons
#define BUTTON_WIDTH                        (120)     // size by X coordinate
#define BUTTON_HEIGHT                       (50)      // size by Y coordinate
//--- for the indication area
#define EDIT_HEIGHT                         (20)      // size by Y coordinate
//--- for group controls
#define GROUP_WIDTH                         (150)     // size by X coordinate
#define LIST_HEIGHT                         (179)     // size by Y coordinate
#define RADIO_HEIGHT                        (56)      // size by Y coordinate
#define CHECK_HEIGHT                        (93)      // size by Y coordinate

#define LABEL_RISK_WIDTH                        (100)      // size by Y coordinate
//+------------------------------------------------------------------+
//| Class CControlsDialog                                            |
//| Usage: main dialog of the Controls application                   |
//+------------------------------------------------------------------+
class CControlsDialog : public CAppDialog
{
private:
    CButton           m_buttonSell;                       // the button object
    CButton           m_buttonBuy;                       // the button object
    TAction           m_actionButtonSell;
    TAction           m_actionButtonBuy;
    TAction           m_actionUseGUI;
    CCheckBox         m_chkUseGUI;                   // the check box group object
    CEdit             m_editRisk;                          // the display field object
    CLabel            m_lblRisk;
    CEdit             m_editRR;                          // the display field object
    CLabel            m_lblRR;
    CLabel            m_lblVolume;
    double            m_rr;

    CLabel            m_lblSLMoney;
    CLabel            m_lblTPMoney;
    CCheckBox         m_chkUseRiskOnGUI;

    long              m_mouseX, m_mouseY;



public:
    CControlsDialog(void);
    ~CControlsDialog(void);
    //--- create
    virtual bool      Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2);
    //--- chart event handler
    virtual bool      OnEvent(const int id,const long &lparam,const double &dparam,const string &sparam);
    void SetActionButtonSell(TAction act)
    {
        m_actionButtonSell = act;
    }
    void SetActionButtonBuy(TAction act)
    {
        m_actionButtonBuy = act;
    }
    void SetActionUseGUI(TAction act)
    {
        m_actionUseGUI = act;
    }
    bool ProcessEvent(const int id,         // event id:
                      // if id-CHARTEVENT_CUSTOM=0-"initialization" event
                      const long&   lparam, // chart period
                      const double& dparam, // price
                      const string& sparam  // symbol)
                     )
    {
        if(id == CHARTEVENT_MOUSE_MOVE) {
            m_mouseX = lparam;
            m_mouseY = (long)dparam;
        }
        ChartEvent(id,lparam,dparam,sparam);
        return true;
    }

    bool CanDraw()
    {
        return m_chkUseGUI.Checked();
    }
    bool CanDraw(bool draw)
    {
        return m_chkUseGUI.Checked(draw);
    }
    bool UseRiskOnGUI()
    {
        return m_chkUseRiskOnGUI.Checked();
    }
    double Risk()
    {
        return StringToDouble(m_editRisk.Text());
    }
    void Risk(double r)
    {
        m_editRisk.Text((string)r);
    }
    double RR()
    {
        return m_rr;
    }
    void Volume(double vol)
    {
        if(vol > 0)
            m_lblVolume.Text("Khối lượng: " + DoubleToString(vol, 2));
        else
            m_lblVolume.Text("Khối lượng: --");
    }

    void SLMoney(double sl)
    {
        if(sl > 0)
            m_lblSLMoney.Text("Lỗ: ~" + DoubleToString(sl, 2) + "$");
        else
            m_lblSLMoney.Text("Lỗ: --");
    }
    void TPMoney(double tp)
    {
        if(tp > 0)
            m_lblTPMoney.Text("Lời: ~" + DoubleToString(tp, 2) + "$");
        else
            m_lblTPMoney.Text("Lời: --");
    }
    void RR(double entry, double sl, double tp)
    {
        if((sl > entry && tp > entry) || (sl < entry && tp < entry)) {
            m_editRR.Text("x:x");
            m_rr = 1;
            return;
        }
        double deltaSL = MathAbs(entry - sl);
        double deltaTP = MathAbs(tp - entry);

        double ratio = 0;
        if(deltaSL > 0) {
            ratio = deltaTP / deltaSL;
            string text = "1:" + DoubleToString(ratio, 1);

            m_editRR.Text(text);
            m_rr = ratio;
        }
    }
    bool MouseInsideDialog()
    {
        long x = m_mouseX, y = m_mouseY;
        int l = Left(), r = Right(), t = Top(), b = Bottom();
        //Print("x=" + x, " y=" + y + " left="+l + " right="+r+ " top=" + t + " bottom=" + b);
        if(x >= l && x <= r
                && y >= t && y <= b)
            return true;
        return false;
    }

protected:
    //--- create dependent controls
    bool              CreateButton1(void);
    bool              CreateButton2(void);
    void              OnClickButton1(void);
    void              OnClickButton2(void);

    bool              CreateLabelRisk(void);
    bool              CreateEditRisk(void);

    bool              CreateLabelRR(void);
    bool              CreateEditRR(void);
    bool              CreateLabelVolume(void);
    bool              CreateLabelSL(void);
    bool              CreateLabelTP(void);

    bool              CreateCheckboxUseGUI(void);
    bool              CreateCheckboxUseRiskOnGUI(void);
    void              OnChange_chkUseRiskOnGUI(void);
    void              OnChangeRisk(void);
    void              OnChangeUseGUI(void);
};
//+------------------------------------------------------------------+
//| Event Handling                                                   |
//+------------------------------------------------------------------+
EVENT_MAP_BEGIN(CControlsDialog)
ON_EVENT(ON_CLICK,m_buttonSell,OnClickButton1)
ON_EVENT(ON_CLICK,m_buttonBuy,OnClickButton2)
//ON_EVENT(ON_CHANGE, m_chkUseGUI, OnChangeRisk)
ON_EVENT(ON_CHANGE, m_chkUseRiskOnGUI, OnChange_chkUseRiskOnGUI)
//ON_EVENT(ON_CHANGE, m_editRisk, OnChangeRisk)
ON_EVENT(ON_CHANGE, m_chkUseGUI, OnChangeUseGUI)
EVENT_MAP_END(CAppDialog)
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CControlsDialog::CControlsDialog(void)
{
}
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CControlsDialog::~CControlsDialog(void)
{
}
//+------------------------------------------------------------------+
//| Create                                                           |
//+------------------------------------------------------------------+
bool CControlsDialog::Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2)
{
    if(!CAppDialog::Create(chart,name,subwin,x1,y1,x2,y2))
        return(false);
//--- create dependent controls
    if(!CreateButton1())
        return(false);
    if(!CreateButton2())
        return(false);

    //if(!CreateLabelRisk())
    //   return(false);
    if(!CreateCheckboxUseRiskOnGUI())
        return(false);
    if(!CreateEditRisk())
        return(false);

    if(!CreateLabelRR())
        return(false);
    if(!CreateEditRR())
        return(false);

    if(!CreateCheckboxUseGUI())
        return(false);

    if(!CreateLabelVolume())
        return(false);

    if(!CreateLabelSL())
        return(false);

    if(!CreateLabelTP())
        return(false);
//--- succeed
    return(true);
}



//+------------------------------------------------------------------+
//| Create the "checkbox" element                                    |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateCheckboxUseRiskOnGUI(void)
{
    int x1 = INDENT_LEFT;
    int y1 = (int)(INDENT_TOP *1.3);
    int x2 = ClientAreaWidth()/2 - INDENT_RIGHT;
    int y2 = y1 + EDIT_HEIGHT;
//
//--- create
    if(!m_chkUseRiskOnGUI.Create(m_chart_id,m_name+"chkUseRiskOnGUI",m_subwin,x1,y1,x2,y2))
        return(false);
    if(!m_chkUseRiskOnGUI.Text("Rủi ro theo %"))
        return(false);
    //if(!m_chkUseRiskOnGUI.Checked(1))
    //    return(false);
    if(!Add(m_chkUseRiskOnGUI))
        return(false);

//--- succeed
    return(true);
}
//+------------------------------------------------------------------+
//| Create the display field                                         |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateEditRisk(void)
{
//--- coordinates
    int x1 = INDENT_LEFT + LABEL_RISK_WIDTH*1.5;
    int y1 = INDENT_TOP;
    int x2 = x1 + LABEL_RISK_WIDTH - INDENT_RIGHT;
    int y2 = y1 + (int)(EDIT_HEIGHT*1.5);
//--- create
    if(!m_editRisk.Create(m_chart_id, m_name + "EditRisk",
                          m_subwin,x1,y1,x2,y2))
        return(false);
    if(!m_editRisk.ReadOnly(false))
        return(false);

    m_editRisk.Text("0.01");

    if(!Add(m_editRisk))
        return(false);
//--- succeed
    return(true);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateLabelRisk(void)
{
//--- coordinates
    int x1 = INDENT_LEFT;
    int y1 = INDENT_TOP;
    int x2 = x1 + LABEL_RISK_WIDTH;
    int y2 = y1 + EDIT_HEIGHT;

    if(!m_lblRisk.Create(m_chart_id, m_name + "lblRisk",
                         m_subwin,x1,y1,x2,y2))
        return(false);

    m_lblRisk.Text("Rủi ro %");
    if(!Add(m_lblRisk))
        return(false);
//--- succeed
    return(true);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateLabelRR(void)
{
//--- coordinates
    int x1 = INDENT_LEFT;
    int y1 = INDENT_TOP + EDIT_HEIGHT*2;
    int x2 = x1 + LABEL_RISK_WIDTH;
    int y2 = y1 + EDIT_HEIGHT;

    if(!m_lblRR.Create(m_chart_id, m_name + "lblRR",
                       m_subwin,x1,y1,x2,y2))
        return(false);

    if(!m_lblRR.Text("Tỉ lệ R:R"))
        return(false);



    if(!Add(m_lblRR))
        return(false);
//--- succeed
    return(true);
}
//+------------------------------------------------------------------+
//| Create the display field                                         |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateEditRR(void)
{
//--- coordinates
    int x1 = INDENT_LEFT + INDENT_RIGHT*8;
    int y1 = INDENT_TOP + EDIT_HEIGHT*2;
    int x2 = ClientAreaWidth() - INDENT_RIGHT;
    int y2 = y1 + (int)(EDIT_HEIGHT * 1.5);
//--- create
    if(!m_editRR.Create(m_chart_id,m_name+"EditRR",
                        m_subwin,x1,y1,x2,y2))
        return(false);
    if(!m_editRR.ReadOnly(true))
        return(false);
    if(!m_editRR.Text("1:3"))
        return false;
    if(!m_editRR.ColorBackground(clrLightGray))
        return(false);

    m_rr = 3;
    if(!Add(m_editRR))
        return(false);
//--- succeed
    return(true);
}
//+------------------------------------------------------------------+
//| Tạo checkbox: "Công cụ vẽ"                                 |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateCheckboxUseGUI(void)
{
    int x1 = INDENT_LEFT;
    int y1 = INDENT_TOP + (EDIT_HEIGHT*4 + CONTROLS_GAP_Y);
    int x2 = ClientAreaWidth() - INDENT_RIGHT;
    int y2 = y1 + EDIT_HEIGHT + 5;
//
//--- create
    if(!m_chkUseGUI.Create(m_chart_id,m_name+"chkUseGUI",m_subwin,x1,y1,x2,y2))
        return(false);
    if(!m_chkUseGUI.Text("Công cụ vẽ"))
        return(false);
    if(!Add(m_chkUseGUI))
        return(false);

//--- succeed
    return(true);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateLabelVolume(void)
{
//--- coordinates
    int x1 = INDENT_LEFT;
    int y1 = INDENT_TOP + EDIT_HEIGHT*6;
    int x2 = x1 + LABEL_RISK_WIDTH;
    int y2 = y1 + EDIT_HEIGHT;

    if(!m_lblVolume.Create(m_chart_id, m_name + "lblVolume",
                           m_subwin,x1,y1,x2,y2))
        return(false);

    m_lblVolume.Text("Khối lượng: --");
    if(!Add(m_lblVolume))
        return(false);

//--- succeed
    return(true);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateLabelSL(void)
{
//--- coordinates
    int x1 = INDENT_LEFT;
    int y1 = INDENT_TOP + EDIT_HEIGHT*8;
    int x2 = x1 + LABEL_RISK_WIDTH;
    int y2 = y1 + EDIT_HEIGHT;

    // ------------------------
    if(!m_lblSLMoney.Create(m_chart_id, m_name + "lblSL",
                            m_subwin,x1,y1,x2,y2))
        return(false);
    m_lblSLMoney.Color(clrRed);
    m_lblSLMoney.Text("Cắt lỗ: --");
    if(!Add(m_lblSLMoney))
        return(false);

//--- succeed
    return(true);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateLabelTP(void)
{
//--- coordinates
    int x1 = INDENT_LEFT + LABEL_RISK_WIDTH * 1.5;
    int y1 = INDENT_TOP + EDIT_HEIGHT*8;
    int x2 = x1 + LABEL_RISK_WIDTH;
    int y2 = y1 + EDIT_HEIGHT;

    // ------------------------
    if(!m_lblTPMoney.Create(m_chart_id, m_name + "lblTP",
                            m_subwin,x1,y1,x2,y2))
        return(false);
    m_lblTPMoney.Color(clrBlue);
    m_lblTPMoney.Text("Lợi nhuận: --");
    if(!Add(m_lblTPMoney))
        return(false);

//--- succeed
    return(true);
}





//+------------------------------------------------------------------+
//| Create the "Button1" button                                      |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateButton1(void)
{
//--- coordinates
    int x1 = INDENT_LEFT + CONTROLS_GAP_X * 5;
    int y1 = INDENT_TOP + (EDIT_HEIGHT*10+CONTROLS_GAP_Y);
    int x2 = x1 + BUTTON_WIDTH;
    int y2 = y1 + BUTTON_HEIGHT;
//--- create
    if(!m_buttonSell.Create(m_chart_id,m_name+"SELL",m_subwin,x1,y1,x2,y2))
        return(false);
    if(!m_buttonSell.Text("Bán"))
        return(false);
    if(!m_buttonSell.ColorBackground(StringToColor("215,92,93")))
        return false;
    if(!m_buttonSell.Color(clrWhite))
        return false;
    if(!Add(m_buttonSell))
        return(false);
    //--- succeed
    return(true);
}


//+------------------------------------------------------------------+
//| Create the "Button2" button                                      |
//+------------------------------------------------------------------+
bool CControlsDialog::CreateButton2(void)
{
//--- coordinates
    int x1=INDENT_LEFT+(BUTTON_WIDTH+CONTROLS_GAP_X * 10);
    int y1=INDENT_TOP+(EDIT_HEIGHT*10 +CONTROLS_GAP_Y);
    int x2=x1+BUTTON_WIDTH;
    int y2=y1+BUTTON_HEIGHT;
//--- create
    if(!m_buttonBuy.Create(m_chart_id,m_name+"Mua",m_subwin,x1,y1,x2,y2))
        return(false);
    if(!m_buttonBuy.Text("Mua"))
        return(false);
    if(!m_buttonBuy.ColorBackground(StringToColor("38,166,154")))
        return false;
    if(!m_buttonBuy.Color(clrWhite))
        return false;
    if(!Add(m_buttonBuy))
        return(false);
//--- succeed
    return(true);
}

//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CControlsDialog::OnClickButton1(void)
{
    if(m_actionButtonSell != NULL)
        m_actionButtonSell();
}
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CControlsDialog::OnClickButton2(void)
{
    if(m_actionButtonBuy != NULL)
        m_actionButtonBuy();
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CControlsDialog::OnChange_chkUseRiskOnGUI(void)
{
    if(m_chkUseRiskOnGUI.Checked()) {
        //m_editRisk.ReadOnly(false);
        m_editRisk.ColorBackground(clrWhite);
    } else {
        //m_editRisk.ReadOnly(true);
        m_editRisk.ColorBackground(clrLightGreen);
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CControlsDialog::OnChangeRisk(void)
{
    // Nothing
}
void CControlsDialog::OnChangeUseGUI(void)
{
    if(m_actionUseGUI != NULL)
        m_actionUseGUI();
}