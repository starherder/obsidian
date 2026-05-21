

CommonDefines.h

目标条件：
```cpp  
UENUM(BlueprintType, Category = "Requirements")  
enum class ERequirementsCondType : uint8  
{  
    // 无效  
    None = 0 UMETA(DisplayName = "None", Hidden),  
  
    // 驾驶指定Id的载具  
    VehicleId = 1 UMETA(DisplayName = "VehicleId"),  
  
    // 完成指定任务  
    MissionID = 2 UMETA(DisplayName = "MissionID"),  
  
    // 完成指定事件  
    EventID = 3 UMETA(DisplayName = "EventID"),  
  
    // 游戏内时间范围  
    Circadian = 4 UMETA(DisplayName = "Circadian"),  
  
    // 天气  
    Weather = 5 UMETA(DisplayName = "Weather"),
    
// --------------------------------------------------------

      
USTRUCT(BlueprintType, Category = "Requirements")  
struct FRequirementsCondInfo  
{  
    GENERATED_USTRUCT_BODY()  
  
    // 条件类型：载具类型，任务id，事件id，时间段，天气等  
    UPROPERTY(EditAnywhere, BlueprintReadOnly)  
    ERequirementsCondType Category = ERequirementsCondType::None;  
  
    // 参数列表：载具类型，任务id，事件id，时间段，天气等  
    UPROPERTY(EditAnywhere, BlueprintReadOnly)  
    TArray<FString> Values;  
  
    // 为了选择，额外的处理  
    UPROPERTY(EditAnywhere, BlueprintReadOnly)  
    TArray<struct FRewardItem> ItemDetails;  
  
    // 本接取条目是否对玩家显示  
    UPROPERTY(EditAnywhere, BlueprintReadOnly, meta = (ToolTip = "向玩家显示文本", DeprecatedProperty))  
    bool bShowToPlayer = true;  
  
    // 对应接取条目所展示的文本内容  
    UPROPERTY(EditAnywhere, BlueprintReadOnly, meta = (ToolTip = "默认提示文本", DeprecatedProperty))  
    FText DisplayText;  
  
    UPROPERTY(EditAnywhere, BlueprintReadOnly, meta = (ToolTip = "特殊条件提示文本"))  
    TArray<FCustomMissionDisplayText> CustomMissionDisplayTexts;  
};
    


```













