

理解了，你的需求拆成两段就是：

# 离线（编辑器阶段）

把那张道路图加载进编辑器，一次性把"路线点"提取/标定出来，存成数据资产，编译运行后这份数据就固定了。
运行时：只读这份数据资产里的路线点，驱动车去移动，不依赖任何图片识别。
这样运行时零成本、零误差，是最稳的 Demo 做法。下面给你完整方案。

## 一、整体数据流
### 编辑器阶段（离线）：
  道路图 → EUW 编辑器工具里点击描点 → 写入 URaceTrackData 资产 → 保存到磁盘
                                        ↑ 图片像素坐标

### 运行时：
  RaceWidget 读取 URaceTrackData.PathPoints → 采样样条 → 车沿路径移动 → 20秒排名



## 二、数据载体：URaceTrackData（C++，可编译）
新建插件模块（沿用上次的 Race2DWidgetPlugin 即可，把下面文件加上）。

Public/RaceTrackData.h
```cpp
#pragma once

#include "CoreMinimal.h"
#include "Engine/DataAsset.h"
#include "RaceTrackData.generated.h"

UCLASS(BlueprintType)
class RACE2DWIDGETPLUGIN_API URaceTrackData : public UDataAsset
{
	GENERATED_BODY()

public:
	// 提取时使用的参考底图（运行时也可当底图）
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Track")
	TSoftObjectPtr<UTexture2D> ReferenceImage;

	// 图片像素尺寸（提取时记录，运行时用于坐标系对齐）
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Track")
	FVector2D ImageSize = FVector2D(900.f, 600.f);

	// ★ 离线提取出的路线点（本地像素坐标，左上角 0,0，x右 y下）
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Track")
	TArray<FVector2D> PathPoints;

	// 各车速度（像素/秒），数量即车辆数
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Track")
	TArray<float> CarSpeeds = { 120.f, 160.f, 140.f, 180.f };

	// 各车颜色
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Track")
	TArray<FLinearColor> CarColors;

	// 各车名
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Track")
	TArray<FString> CarNames = { TEXT("A"), TEXT("B"), TEXT("C"), TEXT("D") };
};
```

在 .Build.cs 里加 AssetTools / UnrealEd 不需要（DataAsset 用 Runtime 模块即可，因为它是 UDataAsset 子类）。保持之前的依赖就行。


## 三、编辑器提取工具（核心，推荐用 Editor Utility Widget）
这是最省事、最准确的"离线提取"方式，纯编辑器内操作，不写 C++，只要建一个 EUW 蓝图。

### 1) 创建 EUW
内容浏览器 → 右键 → Editor Utility → Editor Utility Widget，命名 WBP_TrackExtractor。

### 2) Designer 布局
```
CanvasPanel
 ├─ SizeBox (900×600)             // 和图片同尺寸
 │    └─ Image (绑定 ReferenceImage，显示道路图)
 ├─ Border (透明, 覆盖在 Image 上, 900×600)   // 用来接收鼠标点击
 ├─ Button "保存路线" (下方)
 └─ Text "已采点: 0" (下方)
```

关键点：Image 本身不响应鼠标，必须用一个 Border 盖在它上面，用 Border 的 OnMouseButtonDown 事件拿坐标。

### 3) 变量
在 EUW 的 Variables 里加：
```cpp
TrackData : URaceTrackData 对象引用（指向你要保存的资产）
ImageSize : Vector 2D
```


### 4) 事件图表（蓝图节点描述）

Border 的 `OnMouseButtonDown(Event, Geometry, MouseEvent)：`
```cpp
LocalPos = Geometry.AbsoluteToLocal(MouseEvent.GetScreenSpacePosition())

// 因为 Border 和图片 1:1 对齐，LocalPos 就是图片本地像素坐标
TrackData.PathPoints.Add(LocalPos)
```

刷新 Text "已采点: PathPoints.Num()"
Return Node: FReply → Handled

Button "保存路线" 的 OnClicked：
```cpp
// 把当前 EUW 里的点写回资产并保存
TrackData.SetFlags / (直接改 TrackData.PathPoints 已在上面 Add 进去了)
```


若需要重新指定 ImageSize：TrackData.ImageSize = 当前图片尺寸
EditorAssetLibrary.SaveAsset(TrackData, true)   // 需开启 EditorScriptingUtilities 插件
Print "已保存 N 个点"
EUW Construct / Event Pre Construct：

若 TrackData 已指定 ReferenceImage：
```cpp
	Image.SetBrushFromTexture(TrackData.ReferenceImage)
    ImageSize = TrackData.ImageSize
```

### 5) 使用流程

内容浏览器新建一个 URaceTrackData 资产（右键 → Miscellaneous → Data Asset → 选 RaceTrackData），命名为 DA_Track01，把你的道路图拖进 ReferenceImage，设 ImageSize = 图片真实分辨率。
双击打开 WBP_TrackExtractor，把 TrackData 变量指向 DA_Track01，运行（Run）。
在图片上沿弯道依次点击，每点一下加一个点。
点"保存路线"。
关闭 EUW。提取完成，数据已落盘。
这样"离线提取"就是：编辑器里点几下 → 存盘。运行时完全不碰图片，只读取 DA_Track01.PathPoints。

## 四、运行时改造：RaceWidget 从 DataAsset 读点

修改上次的 RaceWidget，支持直接吃 URaceTrackData。

Public/RaceWidget.h 改动（增加）
```cpp
UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Race2D")
TSoftObjectPtr<URaceTrackData> TrackDataAsset;   // 编辑器指定
Private/RaceWidget.cpp 改动（RebuildWidget）
TSharedRef<SWidget> URaceWidget::RebuildWidget()
{
	// 优先用 DataAsset；没有再用蓝图手填的 PathPoints
	TArray<FVector2D>    Pts  = PathPoints;
	TArray<float>        Spds = CarSpeeds;
	TArray<FLinearColor> Cols = CarColors;
	TArray<FString>      Nms  = CarNames;

	if (!TrackDataAsset.IsNull())
	{
		if (URaceTrackData* TD = TrackDataAsset.LoadSynchronous())
		{
			if (TD->PathPoints.Num() > 0) Pts = TD->PathPoints;
			if (TD->CarSpeeds.Num() > 0)   Spds = TD->CarSpeeds;
			if (TD->CarColors.Num() > 0)   Cols = TD->CarColors;
			if (TD->CarNames.Num() > 0)    Nms  = TD->CarNames;
		}
	}

	MyRace = SNew(SRaceWidget)
		.PathPoints(Pts)
		.CarSpeeds(Spds)
		.CarColors(Cols)
		.CarNames(Nms)
		.RaceDuration(RaceDuration)
		.bShowPath(bShowPath);

	return MyRace.ToSharedRef();
}
```

这样你在关卡蓝图/UMG里只要给 Race Widget 的 TrackDataAsset 指到 DA_Track01，运行时就自动按提取好的路线点跑了，无需再手填坐标。

## 五、（可选）全自动像素提取思路
如果你不想手动点，想"图丢进去自动出路线点"，思路是在编辑器阶段跑一段 C++ 像素分析（仍属离线，运行时不涉及）：
```cpp
// 伪代码：读图片像素 → 阈值找道路像素 → 中心线采样
TArray<FColor> Pixels;
FImageUtils::GetRawData(...) 或 ImageWrapper 读 UTexture2D

for each pixel:
    if 接近"道路色"（如亮度>阈值 或 接近某 RGB）
        标记为道路

// 从起点 BFS/骨架化找连通中心线
// 沿中心线按固定弧长间隔采样 → 得到 PathPoints
```

现实问题：任意截图道路提取是计算机视觉问题（需要边缘检测/Sobel + 细化 + 中心线追踪，或用 OpenCV 插件）。Demo 阶段手动点 8~15 个点又快又准，强烈建议走 EUW 手动描点路线。


# 加入服务器控制赛车速度，服务器预判赛车结果

## 一、核心洞察：这里"预判"= 精确结果
因为车是纯确定性运动——位置只由 距离 = 速度 × 时间（封顶到赛道路长）决定，没有任何玩家输入、没有任何随机数。

所以：

- 服务器控制速度 → 把 CarSpeeds 设为权威、只下发给客户端。
- 服务器预判结果 → 在 t=0 就能瞬间算出 最终距离 = min(Speed × 20, PathLength)，排序即得最终排名。这不是估计，是精确值。
- 架构因此非常简单，不需要服务器每帧同步坐标（太浪费带宽），而是：

| 服务器(权威)                       | 客户端(表现)                      |
| ----------------------------- | ---------------------------- |
| 持有 CarSpeeds ★                | 复制 CarSpeeds                 |
| 持有 PathLength ★               | 读取本地 DA_Track01 的 PathPoints |
| RaceStartTime ★               | 用服务器时钟算 Elapsed              |
| 20s后 ComputeResult → Result ★ | OnRep_Result 显示排名            |

客户端拿速度 + 固定路径，用同一套确定性公式本地跑动画；服务器只在起点和终点各发一次数据。

## 二、数据/结构体（RaceNetTypes.h）

``` cpp
#pragma once
#include "CoreMinimal.h"
#include "Engine/DataAsset.h"
#include "RaceNetTypes.generated.h"

USTRUCT(BlueprintType)
struct FRaceResultEntry
{
	GENERATED_BODY()

	UPROPERTY(BlueprintReadOnly) FString CarName;
	UPROPERTY(BlueprintReadOnly) float   Distance = 0.f;
	UPROPERTY(BlueprintReadOnly) float   Speed    = 0.f;
	UPROPERTY(BlueprintReadOnly) int32   Rank     = 0;
};

USTRUCT(BlueprintType)
struct FRaceResult
{
	GENERATED_BODY()

	UPROPERTY(BlueprintReadOnly) TArray<FRaceResultEntry> Entries;
	UPROPERTY(BlueprintReadOnly) bool bFinal = false; // false=预判, true=最终结果
};

```

## 三、权威 GameState（RaceGameState.h / .cpp）

RaceGameState.h
```cpp
#pragma once
#include "CoreMinimal.h"
#include "GameFramework/GameStateBase.h"
#include "RaceNetTypes.h"
#include "RaceGameState.generated.h"

UCLASS()
class ARaceGameState : public AGameStateBase
{
	GENERATED_BODY()

public:
	// ---- 服务器权威数据（复制到客户端）----
	UPROPERTY(ReplicatedUsing = OnRep_CarSpeeds)
	TArray<float> CarSpeeds;

	UPROPERTY(ReplicatedUsing = OnRep_CarNames)
	TArray<FString> CarNames;

	UPROPERTY(Replicated)
	float PathLength = 0.f;        // 服务器从 DataAsset 算好下发

	UPROPERTY(Replicated)
	float RaceDuration = 20.f;

	UPROPERTY(Replicated)
	float RaceStartTime = -1.f;    // 服务器世界时间，客户端用作同步时钟

	UPROPERTY(ReplicatedUsing = OnRep_Result)
	FRaceResult Result;            // 预判 + 最终结果

	// ---- 服务器接口 ----
	UFUNCTION(BlueprintCallable, Category = "Race")
	void StartRace(const TArray<float>& InSpeeds, const TArray<FString>& InNames,
	               float InPathLength, float InDuration = 20.f);

	// 服务器瞬时预判（t=0 即可调用）
	UFUNCTION(BlueprintCallable, Category = "Race")
	FRaceResult PredictResult() const;

	// 客户端可用：用服务器时钟推算当前已用时间
	UFUNCTION(BlueprintPure, Category = "Race")
	float GetElapsed() const;

protected:
	virtual void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>&) const override;
	void ComputeResult(FRaceResult& Out, bool bFinal) const;

	UFUNCTION() void OnRep_CarSpeeds();
	UFUNCTION() void OnRep_CarNames();
	UFUNCTION() void OnRep_Result();

private:
	FTimerHandle EndTimer;
};
```


RaceGameState.cpp
```cpp
#include "RaceGameState.h"
#include "Net/UnrealNetwork.h"

void ARaceGameState::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& Out) const
{
	Super::GetLifetimeReplicatedProps(Out);
	DOREPLIFETIME(ARaceGameState, CarSpeeds);
	DOREPLIFETIME(ARaceGameState, CarNames);
	DOREPLIFETIME(ARaceGameState, PathLength);
	DOREPLIFETIME(ARaceGameState, RaceDuration);
	DOREPLIFETIME(ARaceGameState, RaceStartTime);
	DOREPLIFETIME(ARaceGameState, Result);
}

void ARaceGameState::StartRace(const TArray<float>& InSpeeds,
                               const TArray<FString>& InNames,
                               float InPathLength, float InDuration)
{
	if (!HasAuthority()) return;

	CarSpeeds    = InSpeeds;
	CarNames     = InNames;
	PathLength   = InPathLength;
	RaceDuration = InDuration;
	RaceStartTime = GetWorld()->GetTimeSeconds();

	// 立即预判：开赛瞬间就给出"预测榜"
	Result = PredictResult();

	// 20 秒后落定"最终榜"
	GetWorld()->GetTimerManager().SetTimer(EndTimer, [this]()
	{
		ComputeResult(Result, true);
	}, RaceDuration, false);
}

FRaceResult ARaceGameState::PredictResult() const
{
	FRaceResult R;
	ComputeResult(R, false);
	return R;
}

void ARaceGameState::ComputeResult(FRaceResult& Out, bool bFinal) const
{
	TArray<FRaceResultEntry> Entries;
	for (int32 i = 0; i < CarSpeeds.Num(); ++i)
	{
		FRaceResultEntry E;
		E.CarName  = (i < CarNames.Num()) ? CarNames[i]
		                                   : FString::Printf(TEXT("Car%d"), i + 1);
		E.Speed    = CarSpeeds[i];
		// ★ 与客户端本地模拟完全一致的公式
		E.Distance = FMath::Min(CarSpeeds[i] * RaceDuration, PathLength);
		Entries.Add(E);
	}
	Entries.Sort([](const FRaceResultEntry& A, const FRaceResultEntry& B)
	{
		return A.Distance > B.Distance;
	});
	for (int32 i = 0; i < Entries.Num(); ++i) Entries[i].Rank = i + 1;

	Out.Entries = Entries;
	Out.bFinal  = bFinal;
}

float ARaceGameState::GetElapsed() const
{
	if (RaceStartTime < 0.f) return 0.f;
	return GetServerWorldTimeSeconds() - RaceStartTime; // 用服务器时钟，所有客户端同步
}

void ARaceGameState::OnRep_CarSpeeds()  {} // 由客户端 UMG 监听后初始化 RaceWidget
void ARaceGameState::OnRep_CarNames()   {}
void ARaceGameState::OnRep_Result()     {} // 由客户端 UMG 刷新排名面板
```


## 四、客户端整合（UMG 侧逻辑）

在持有 RaceWidget 的 UMG / PlayerController 里：

```cpp
void AMyHUD::BindRace(ARaceGameState* GS)
{
	GS->OnRep_CarSpeeds; // 实际用委托或 Tick 监听
	// 简单做法：在收到复制后调用
	RaceWidget->SetSpeeds(GS->CarSpeeds);
	RaceWidget->SetNames(GS->CarNames);
	RaceWidget->StartRaceWithClock(/* 用 GS->GetElapsed 同步 */);
}
```

并且把 SRaceWidget 的本地计时改成读服务器时钟而不是 ActiveTimer 累加（保证所有客户端画面同步）：

RaceGameState.cpp
```cpp

// SRaceWidget 里
void SRaceWidget::TickVisual(float ServerElapsed)
{
	Elapsed = ServerElapsed;
	for (auto& Car : Cars)
	{
		Car.Distance = FMath::Min(Car.Speed * Elapsed, PathLength); // 同公式
		Car.Pos = GetPosAtDistance(Car.Distance, Car.Dir);
	}
	if (Elapsed >= RaceDuration) UpdateRanking();
}
```

若你沿用上次的 ActiveTimer 写法也行（Demo 20 秒误差可忽略），但用 GS->GetElapsed() 是更"服务器同步"的正解。

## 五、服务器怎么设速度（三种玩法）
场景	做法
固定配置	服务器 StartRace 时从 DA_Track01.CarSpeeds 直接读
随机/编排	服务器按规则生成速度数组再 StartRace
动态操控（rubber-band）	赛中服务器改 CarSpeeds 并 MarkDirtyForReplication()，客户端 OnRep_CarSpeeds 即时重读——这就是"服务器实时控制速度"
动态改速度示例（服务器）：

```cpp
void ARaceGameState::SetCarSpeed(int32 Index, float NewSpeed)
{
	if (!HasAuthority() || !CarSpeeds.IsValidIndex(Index)) return;
	CarSpeeds[Index] = NewSpeed;
	MARK_PROPERTY_DIRTY_FROM_NAME(ARaceGameState, CarSpeeds, this);
	// 速度变了，预判榜也跟着变
	Result = PredictResult(); // 实时刷新预测
}
```
