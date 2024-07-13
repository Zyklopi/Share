#property copyright "Your Name"
#property link      "https://www.yourwebsite.com"
#property version   "1.00"
#property strict
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots   4

// Input parameters
input int    Length = 14;
input double Multiplier = 0.5;
input color  ATRTextColor = clrBlue;
input color  LowTextColor = clrLimeGreen;
input color  HighTextColor = clrRed;
input color  LowLineColor = clrLimeGreen;
input color  HighLineColor = clrRed;

// Buffers
double ShortStopLossBuffer[];
double LongStopLossBuffer[];
double CurrentShortStopLossBuffer[];
double CurrentLongStopLossBuffer[];
double TRBuffer[];
double RmaBuffer[];

// Names for the horizontal lines
string ShortStopLossLineName = "ShortStopLossLine";
string LongStopLossLineName = "LongStopLossLine";

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize buffers
    SetIndexBuffer(0, ShortStopLossBuffer, INDICATOR_DATA);
    SetIndexBuffer(1, LongStopLossBuffer, INDICATOR_DATA);
    SetIndexBuffer(2, CurrentShortStopLossBuffer, INDICATOR_DATA);
    SetIndexBuffer(3, CurrentLongStopLossBuffer, INDICATOR_DATA);
    SetIndexBuffer(4, TRBuffer, INDICATOR_CALCULATIONS);
    SetIndexBuffer(5, RmaBuffer, INDICATOR_CALCULATIONS);
    
    // Set line styles
    PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_LINE);
    PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_LINE);
    PlotIndexSetInteger(2, PLOT_DRAW_TYPE, DRAW_LINE);
    PlotIndexSetInteger(3, PLOT_DRAW_TYPE, DRAW_LINE);
    
    // Set line colors
    PlotIndexSetInteger(0, PLOT_LINE_COLOR, HighLineColor);
    PlotIndexSetInteger(1, PLOT_LINE_COLOR, LowLineColor);
    PlotIndexSetInteger(2, PLOT_LINE_COLOR, HighLineColor);
    PlotIndexSetInteger(3, PLOT_LINE_COLOR, LowLineColor);
    
    // Set line labels
    PlotIndexSetString(0, PLOT_LABEL, "ATR Short Stop Loss");
    PlotIndexSetString(1, PLOT_LABEL, "ATR Long Stop Loss");
    PlotIndexSetString(2, PLOT_LABEL, "Current ATR Short Stop Loss");
    PlotIndexSetString(3, PLOT_LABEL, "Current ATR Long Stop Loss");
    
    // Set line widths
    PlotIndexSetInteger(2, PLOT_LINE_WIDTH, 2);
    PlotIndexSetInteger(3, PLOT_LINE_WIDTH, 2);
    
    // Create horizontal lines
    ObjectCreate(0, ShortStopLossLineName, OBJ_HLINE, 0, 0, 0);
    ObjectSetInteger(0, ShortStopLossLineName, OBJPROP_COLOR, HighLineColor);
    ObjectSetInteger(0, ShortStopLossLineName, OBJPROP_STYLE, STYLE_DASH);
    ObjectSetInteger(0, ShortStopLossLineName, OBJPROP_WIDTH, 1);

    ObjectCreate(0, LongStopLossLineName, OBJ_HLINE, 0, 0, 0);
    ObjectSetInteger(0, LongStopLossLineName, OBJPROP_COLOR, LowLineColor);
    ObjectSetInteger(0, LongStopLossLineName, OBJPROP_STYLE, STYLE_DASH);
    ObjectSetInteger(0, LongStopLossLineName, OBJPROP_WIDTH, 1);
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
    if(rates_total < Length) return(0);

    int start = prev_calculated - 1;
    if(start < 0) start = 0;

    // Calculate True Range
    for(int i = MathMax(start, 1); i < rates_total && !IsStopped(); i++)
    {
        double hl = high[i] - low[i];
        double hc = MathAbs(high[i] - close[i-1]);
        double lc = MathAbs(low[i] - close[i-1]);
        TRBuffer[i] = MathMax(hl, MathMax(hc, lc));
    }

    // Calculate RMA of True Range
    if(start < Length) start = Length;
    for(int i = start; i < rates_total && !IsStopped(); i++)
    {
        if(i == Length)
        {
            double sum = 0;
            for(int j = 0; j < Length; j++)
            {
                sum += TRBuffer[i-j];
            }
            RmaBuffer[i] = sum / Length;
        }
        else
        {
            RmaBuffer[i] = (RmaBuffer[i-1] * (Length - 1) + TRBuffer[i]) / Length;
        }

        double atr = RmaBuffer[i] * Multiplier;
        
        ShortStopLossBuffer[i] = high[i] + atr;
        LongStopLossBuffer[i] = low[i] - atr;
        
        // Update current ATR stop loss lines
        CurrentShortStopLossBuffer[i] = ShortStopLossBuffer[i];
        CurrentLongStopLossBuffer[i] = LongStopLossBuffer[i];
    }
    
    // Update horizontal lines and draw text on the chart (last known values)
    if(rates_total > 0)
    {
        int last_index = rates_total - 1;
        double shortStopLoss = ShortStopLossBuffer[last_index];
        double longStopLoss = LongStopLossBuffer[last_index];
        
        ObjectSetDouble(0, ShortStopLossLineName, OBJPROP_PRICE, shortStopLoss);
        ObjectSetDouble(0, LongStopLossLineName, OBJPROP_PRICE, longStopLoss);
        
        string atrText = "ATR: " + DoubleToString(RmaBuffer[last_index] * Multiplier, 2);
        string highText = "H: " + DoubleToString(shortStopLoss, 2);
        string lowText = "L: " + DoubleToString(longStopLoss, 2);
        
        ObjectCreate(0, "ATRText", OBJ_LABEL, 0, 0, 0);
        ObjectSetString(0, "ATRText", OBJPROP_TEXT, atrText);
        ObjectSetInteger(0, "ATRText", OBJPROP_COLOR, ATRTextColor);
        ObjectSetInteger(0, "ATRText", OBJPROP_CORNER, CORNER_LEFT_LOWER);
        ObjectSetInteger(0, "ATRText", OBJPROP_XDISTANCE, 10);
        ObjectSetInteger(0, "ATRText", OBJPROP_YDISTANCE, 40);
        
        ObjectCreate(0, "HighText", OBJ_LABEL, 0, 0, 0);
        ObjectSetString(0, "HighText", OBJPROP_TEXT, highText);
        ObjectSetInteger(0, "HighText", OBJPROP_COLOR, HighTextColor);
        ObjectSetInteger(0, "HighText", OBJPROP_CORNER, CORNER_LEFT_LOWER);
        ObjectSetInteger(0, "HighText", OBJPROP_XDISTANCE, 10);
        ObjectSetInteger(0, "HighText", OBJPROP_YDISTANCE, 20);
        
        ObjectCreate(0, "LowText", OBJ_LABEL, 0, 0, 0);
        ObjectSetString(0, "LowText", OBJPROP_TEXT, lowText);
        ObjectSetInteger(0, "LowText", OBJPROP_COLOR, LowTextColor);
        ObjectSetInteger(0, "LowText", OBJPROP_CORNER, CORNER_LEFT_LOWER);
        ObjectSetInteger(0, "LowText", OBJPROP_XDISTANCE, 10);
        ObjectSetInteger(0, "LowText", OBJPROP_YDISTANCE, 0);
    }
    
    return(rates_total);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    ObjectDelete(0, ShortStopLossLineName);
    ObjectDelete(0, LongStopLossLineName);
    ObjectDelete(0, "ATRText");
    ObjectDelete(0, "HighText");
    ObjectDelete(0, "LowText");
}
