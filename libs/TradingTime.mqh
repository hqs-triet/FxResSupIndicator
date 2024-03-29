//#include "Utils.mqh"

input bool      InpCancelPendingOrdersOutOfTradingTime = false; // Cancel all pending orders when out of trading time
input bool      InpNoTradingTimeOnSatSun = true;                // No trading on Saturday and Sunday?

input bool   InpTradingWeekDays = true;                    // Ngày giao dịch trong tuần (ưu tiên)
input bool   InpTradingWeekDays_Mon = true;                // |- Thứ 2
input bool   InpTradingWeekDays_Tue = true;                // |- Thứ 3
input bool   InpTradingWeekDays_Wed = true;                // |- Thứ 4
input bool   InpTradingWeekDays_Thu = true;                // |- Thứ 5
input bool   InpTradingWeekDays_Fri = true;                // |- Thứ 6

input bool      InpTradingTimeOnMonday = false;                 // Trading on Monday early? (this is prior than daily)
input string    InpTradingMondayTimeStart = "12:00:00";         // |- The starting time to trade (HH:mm:ss) (0h~23h)
input int       InpTradingMondayTimeStartHours = 12;            // |- The starting time to trade (24 hours)

input bool      InpTradingTimeOnFriday = false;             // Trading on end of Firday ? (this is prior than daily)
input string    InpTradingFridayTimeEnd = "20:00:00";       // |- The ending time to trade (HH:mm:ss) (~23h)
input int       InpTradingFridayTimeEndHours = 20;          // |- The ending time to trade (24 hours)

input bool      InpTradingDailyTime = false;                // Check trading time daily ?
input string    InpTradingDailyTimeStart = "";              // |- The starting time to trade daily (HH:mm:ss), empty if not use.
input int       InpTradingDailyTimeStartHours = 0;         // |- The starting time to trade daily (24 hours)
input string    InpTradingDailyTimeEnd = "";                // |- The ending time to trade daily (HH:mm:ss), empty if not use.
input int       InpTradingDailyTimeEndHours = 0;           // |- The ending time to trade daily (24 hours)

bool isShowedMsgTrade = false;
bool isShowedMsgNoTrade = false;


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//bool IsTradingTime(string timeStart, string timeEnd)
//  {
//    
//    datetime currentTime = TimeCurrent();
//    // Dont trade on Saturday, Sunday
//    //MqlDateTime structCurrentTime;
//    //if(TimeToStruct(currentTime, structCurrentTime))
//    //{
//    //   if(structCurrentTime.day_of_week == 0
//    //      || structCurrentTime.day_of_week == 6)
//    //      return false;
//    //}
//
//
//   if(IsValidTime(timeStart) && IsValidTime(timeEnd))
//     {
//
//      datetime inpStartTime = StringToTime(timeStart);
//      datetime inpEndTime = StringToTime(timeEnd);
//
//      if(inpStartTime < inpEndTime)
//        {
//         if(currentTime >= inpStartTime && currentTime <= inpEndTime)
//           {
//            return true;
//           }
//        }
//      else
//         if(inpStartTime > inpEndTime)
//           {
//            if(currentTime >= inpStartTime || currentTime <= inpEndTime)
//              {
//               return true;
//              }
//           }
//     }
//   return false;
//  }
//

bool ValidateTradingTime()
{
    datetime currentTime = TimeCurrent();
    MqlDateTime structCurrentTime;
    TimeToStruct(currentTime, structCurrentTime);
    
    bool isSundayOK = true, isSaturdayOK = true;
    if(InpNoTradingTimeOnSatSun)
    {
        isSaturdayOK = structCurrentTime.day_of_week != 6;
        isSundayOK = structCurrentTime.day_of_week != 0;
    }
    
    bool isWeekdaysOK = true;
    
    if(InpTradingWeekDays)
    {
        // Thứ 2
        if(structCurrentTime.day_of_week == 1 && !InpTradingWeekDays_Mon)
            isWeekdaysOK = false;
        // Thứ 3
        if(structCurrentTime.day_of_week == 2 && !InpTradingWeekDays_Tue)
            isWeekdaysOK = false;
        // Thứ 4
        if(structCurrentTime.day_of_week == 3 && !InpTradingWeekDays_Wed)
            isWeekdaysOK = false;
        // Thứ 5
        if(structCurrentTime.day_of_week == 4 && !InpTradingWeekDays_Thu)
            isWeekdaysOK = false;
        // Thứ 6
        if(structCurrentTime.day_of_week == 5 && !InpTradingWeekDays_Fri)
            isWeekdaysOK = false;
    }
            
    bool isMondayOK = true;
    
    
    if(InpTradingTimeOnMonday)
    {
        string processInpTradingMondayTimeStart = InpTradingMondayTimeStart;
        if(IsEmptyOrWhitespace(InpTradingMondayTimeStart))
        {
            processInpTradingMondayTimeStart =  InpTradingMondayTimeStartHours + ":00:00";
            if(InpTradingMondayTimeStartHours < 10)
                processInpTradingMondayTimeStart = "0" + processInpTradingMondayTimeStart;
        }
        
        if(structCurrentTime.day_of_week == 1)
        {
            datetime checkingMondayStartTime = StringToTime(processInpTradingMondayTimeStart);
            if(currentTime < checkingMondayStartTime)
            {
                isMondayOK = false;
            }
        }
    }
    
    bool isFridayOK = true;
    
    if(InpTradingTimeOnFriday)
    {
        string processInpTradingFridayTimeEnd = InpTradingFridayTimeEnd;
        if(IsEmptyOrWhitespace(InpTradingFridayTimeEnd))
        {
            processInpTradingFridayTimeEnd =  InpTradingFridayTimeEndHours + ":00:00";
            if(InpTradingFridayTimeEndHours < 10)
                processInpTradingFridayTimeEnd = "0" + processInpTradingFridayTimeEnd;
        }
        
        if(structCurrentTime.day_of_week == 5)
        {
            datetime checkingFridayEndTime = StringToTime(processInpTradingFridayTimeEnd);
            if(currentTime > checkingFridayEndTime)
            {
                isFridayOK = false;
            }
        }
    }
    
    
    bool isDailyOK = true;
    if(InpTradingDailyTime)
    {
        string processInpTradingDailyTimeStart = InpTradingDailyTimeStart;
        string processInpTradingDailyTimeEnd = InpTradingDailyTimeEnd;
        if(IsEmptyOrWhitespace(InpTradingDailyTimeStart))
        {
            processInpTradingDailyTimeStart = InpTradingDailyTimeStartHours + ":00:00";
            if(InpTradingDailyTimeStartHours < 10)
                processInpTradingDailyTimeStart = "0" + processInpTradingDailyTimeStart;
        }
        if(IsEmptyOrWhitespace(InpTradingDailyTimeEnd))
        {
            processInpTradingDailyTimeEnd = InpTradingDailyTimeEndHours + ":00:00";
            if(InpTradingDailyTimeEndHours < 10)
                processInpTradingDailyTimeEnd = "0" + processInpTradingDailyTimeEnd;
        }
        if(!IsTradingTime(processInpTradingDailyTimeStart, processInpTradingDailyTimeEnd))
        {
            isDailyOK = false;
        }
        
    }
    
    if(isWeekdaysOK && isMondayOK && isFridayOK && isSaturdayOK && isSundayOK && isDailyOK)
    {
        if(!isShowedMsgTrade)
        {
            Print("(^.^) It's time to trade! (" 
                  + structCurrentTime.hour + ":" 
                  + structCurrentTime.min + ":" 
                  + structCurrentTime.sec + ")");
            isShowedMsgTrade = true;
            isShowedMsgNoTrade = false;
        }
    }
    else
    {
        if(!isShowedMsgNoTrade)
        {
            Print("(!+.+!) It's time to relax -> No trading at all! (" 
                  + structCurrentTime.hour + ":" 
                  + structCurrentTime.min + ":" 
                  + structCurrentTime.sec + ")");
            isShowedMsgNoTrade = true;
            isShowedMsgTrade = false;
        }
        return false;
    }
    
    return true;
}
