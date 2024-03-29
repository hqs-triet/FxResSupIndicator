
#include <Trade\PositionInfo.mqh>
#include  "ExpertWrapper.mqh"
#include  "..\libs\Common.mqh"

// ===================================================================
// Tham số đầu vào [start]
// ===================================================================
input int    InpGridStepUnitPoints = 500;  // Đơn vị khoảng cách của grid (points)
input double InpGridTargetProfit = 10.0;         // Số tiền mong muốn chốt lời
input bool   InpGridAllowBuy = true;       // Cho phép mở lệnh BUY
input bool   InpGridAllowSell = true;       // Cho phép mở lệnh SELL
// ===================================================================
// Tham số đầu vào [end]
// ===================================================================

// ============================================
// Class thể hiện phương pháp "Grid"
// ============================================
class CGrid
{
    private:
        // -------------------------------------
        // Khai báo chung
        string m_symbolCurrency;
        CTrade m_trader;
        AllSeriesInfo m_infoCurrency;
        ENUM_TIMEFRAMES m_tf;
        string m_appendComment;
        ulong m_magicNumber;
        string m_interPreComment;
        bool m_disabled;
        
        // -------------------------------------
        int m_zoneGrid, m_step;
        double m_ratioTP;
        
    public:
        
        // Thiết lập ghi chú khi tạo lệnh
        void SetAppendComment(string appendComment)
        {
            m_appendComment = appendComment;
        }
        void InternalComment(string comment)
        {
            m_interPreComment = comment;
        }
        void Disable(bool disable)
        {
            m_disabled = disable;
            if(disable)
                CloseAllPendingOrders();
        }
        
        // Khởi tạo các thông số cho đối tượng CHedge
        bool Init(string symbol, ENUM_TIMEFRAMES tf, 
                       CTrade &trader, AllSeriesInfo &infoCurrency,
                       ulong magicNumber)
        {
            m_symbolCurrency = symbol;
            m_tf = tf;
            m_trader = trader;
            m_infoCurrency = infoCurrency;
            m_magicNumber = magicNumber;

            m_disabled = false;
            m_interPreComment = "";
            return true;
        }
        
        // ===================================
        // Xử lý chính
        // ===================================
        void Process(int limit)
        {
            if(m_disabled)
                return;
            
            // ==================================================================================
            // Nếu chưa có lệnh nào mở thì đóng hết các lệnh chờ [start]
            // ==================================================================================
            int countPos = GetActivePositions(m_symbolCurrency, m_magicNumber, true, true, m_appendComment);
            if(countPos == 0)
            {
                if(GetPendingOrdersByType(m_symbolCurrency, m_magicNumber, ORDER_TYPE_BUY_LIMIT, m_appendComment) > 0 ||
                   GetPendingOrdersByType(m_symbolCurrency, m_magicNumber, ORDER_TYPE_BUY_STOP, m_appendComment) > 0 ||
                   GetPendingOrdersByType(m_symbolCurrency, m_magicNumber, ORDER_TYPE_SELL_LIMIT, m_appendComment) > 0 ||
                   GetPendingOrdersByType(m_symbolCurrency, m_magicNumber, ORDER_TYPE_SELL_STOP, m_appendComment) > 0)
                {
                    CloseAllPendingOrders();
                }
                return;
            
            }
            // ==================================================================================
            // Nếu chưa có lệnh nào mở thì đóng hết các lệnh chờ [end]
            // ==================================================================================
            
            
            
            // ==================================================================================
            // Kiểm tra: đạt được lợi nhuận mong đợi -> đóng toàn bộ lệnh [start]
            // ==================================================================================
            string comment = CombineComment();
            double runtimeProfit = AccountInfoDouble(ACCOUNT_EQUITY) - AccountInfoDouble(ACCOUNT_BALANCE);
            if(runtimeProfit > InpGridTargetProfit)
            {
                CloseAllBuyPositions(m_trader, m_symbolCurrency, m_magicNumber, 0, comment);
                CloseAllPendingOrders();
            }
            // ==================================================================================
            // Kiểm tra: đạt được lợi nhuận mong đợi -> đóng toàn bộ lệnh [end]
            // ==================================================================================
            
            
            // ==================================================================================
            // Lấy thông tin của lệnh đầu tiên [start]
            // ==================================================================================
            ulong outBuyTickets[], outSellTickets[];
            string firstPosComment = m_appendComment + ";10000;";
            if(SearchActiveOpenPosition(m_symbolCurrency, m_magicNumber, firstPosComment, false, true, outBuyTickets) == 0 &&
               SearchActiveOpenPosition(m_symbolCurrency, m_magicNumber, firstPosComment, true, false, outSellTickets) == 0)
                return;
            
            CPositionInfo posBuyInfo, posSellInfo;
            if(!posBuyInfo.SelectByTicket(outBuyTickets[0]))
                return;
            if(!posSellInfo.SelectByTicket(outSellTickets[0]))
                return;
            double firstPosBuyEntry = posBuyInfo.PriceOpen();
            double firstPosSellEntry = posSellInfo.PriceOpen();
            
            // ==================================================================================
            // Lấy thông tin của lệnh đầu tiên [end]
            // ==================================================================================
            
            
            // ==================================================================================
            // Xử lý mở các lệnh tại mức trong grid [start]
            // ==================================================================================
            double stepPriceShift = PointsToPriceShift(m_symbolCurrency, InpGridStepUnitPoints);
            string commentAbove = CombineComment() + ";12;";
            string commentBelow = CombineComment() + ";11;";
            for(int idx = 1; idx <= 4; idx++)
            {
                string commentAboveLevel = commentAbove + idx + ";";
                string commentBelowLevel = commentBelow + idx + ";";
                
                // --------------------------------------------------
                // Các lệnh phía trên của lệnh đầu tiên [start]
                // --------------------------------------------------
                ulong aboveBuyTickets[], aboveSellTickets[];
                int lenSellOrders = SearchPendingPosition(m_symbolCurrency, m_magicNumber, commentAboveLevel, true, false, aboveSellTickets);
                int lenBuyOrders = SearchPendingPosition(m_symbolCurrency, m_magicNumber, commentAboveLevel, false, true, aboveBuyTickets);
                double entry = firstPosBuyEntry;
                COrderInfo orderInfo;
                if(lenBuyOrders == 0)
                {
                    entry = orderInfo.PriceOpen();
                } 
                // --------------------------------------------------
                // Các lệnh phía trên của lệnh đầu tiên [start]
                // --------------------------------------------------
                
                
                // --------------------------------------------------
                // Các lệnh bên dưới của lệnh đầu tiên [start]
                // --------------------------------------------------
                ulong belowBuyTickets[], belowSellTickets[];
                
                // --------------------------------------------------
                // Các lệnh bên dưới của lệnh đầu tiên [end]
                // --------------------------------------------------
            }
            // ==================================================================================
            // Xử lý mở các lệnh tại mức trong grid [end]
            // ==================================================================================

        }
    protected:
        string CombineComment()
        {
            return m_appendComment + "_" + m_interPreComment;
        }
        
        // =====================================
        // Cập nhật SL và TP cho ticket
        // =====================================
        bool UpdateSLTP(ulong ticket, double sl, double tp)
        {
            CPositionInfo pos;
            pos.SelectByTicket(ticket);
            return m_trader.PositionModify(ticket, sl, tp);
        }
        // ===================================
        // Đóng toàn bộ lệnh chờ SELL và BUY
        // ===================================
        void CloseAllPendingOrders()
        {
            string comment = CombineComment();
            ClosePendingOrders(m_trader, m_symbolCurrency, m_magicNumber, ORDER_TYPE_BUY_STOP, comment);
            ClosePendingOrders(m_trader, m_symbolCurrency, m_magicNumber, ORDER_TYPE_SELL_STOP, comment);
            ClosePendingOrders(m_trader, m_symbolCurrency, m_magicNumber, ORDER_TYPE_BUY_LIMIT, comment);
            ClosePendingOrders(m_trader, m_symbolCurrency, m_magicNumber, ORDER_TYPE_SELL_LIMIT, comment);
        }
        
        // ===================================
        // Tinh tổng lợi nhuận bao gồm bù trừ phí swap
        // ===================================
        double GetTotalProfit()
        {
            double sumProfit = 0;
        
            for(int i=PositionsTotal()-1; i>=0; i--) {
                string CounterSymbol=PositionGetSymbol(i);
                ulong ticket = PositionGetTicket(i);
        
                if(PositionSelectByTicket(ticket)) {
                    if(m_symbolCurrency == CounterSymbol
                            && PositionGetInteger(POSITION_MAGIC) == m_magicNumber) {
                        string comment = PositionGetString(POSITION_COMMENT);
                        
                        // Init position
                        string initPosComment = m_appendComment + ";01;";
                        if(StringFind(comment, initPosComment) >= 0)
                        {
                            sumProfit += PositionGetDouble(POSITION_PROFIT);
                            sumProfit += PositionGetDouble(POSITION_SWAP);
                            sumProfit += PositionGetDouble(POSITION_COMMISSION);
                        }
                        // Topup
                        string topupComment = CombineComment() + ";";
                        if(StringFind(comment, topupComment) >= 0) 
                        {
                            sumProfit += PositionGetDouble(POSITION_PROFIT);
                            sumProfit += PositionGetDouble(POSITION_SWAP);
                            sumProfit += PositionGetDouble(POSITION_COMMISSION);
                        }
                    }
                }
            }
            return sumProfit;
        }
        
        
};