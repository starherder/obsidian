
## 描述

玩家身上的数据会发送给PGOS。

当前是数据修改后标记为dirty，然后定时将所有dirty数据一条条通过SetPlayerKVData发送给Pgos后台。几乎每一条数据都有一个消息通信，性能拉跨。

目标是将所有dirty数据放到map里， 然后通过BatchSetPlayerKVData一次性发送，提高性能。

`ABasePlayerState::TickPgosDirtyData`
`SetPlayerKVData`和`SetOneOfPlayerKVData`可以用`BatchSetPlayerKVData`替代


## 当前用法

```cpp
  
void ABasePlayerState::TickPgosDirtyData()  
{  
    if (IsABot())  // 机器人滚粗
    {
		return;  
    }    
    
    // PgosDataDirtyFlags 是 TIntegerBitMask<EPgosPlayerDataDirtyFlags> 类型
    // PgosDataDirtyFlags()是因为它重载了括号，表示！=0
    if (PgosDataDirtyFlags() && GetPlayerProfileIfReady())  
    {       
	    // 对于每一个数据分类（基础信息、服饰、功能解锁等）
	    for (int32 i = static_cast<int32>(EPgosPlayerDataDirtyFlags::None) + 1; 
		    i < static_cast<int32>(EPgosPlayerDataDirtyFlags::Max); ++i)  
        {  
			// 如果该数据分类是脏数据，将该分类数据同步到PGOS
	       if (PgosDataDirtyFlags[i])
           {
	          switch (static_cast<EPgosPlayerDataDirtyFlags>(i))  
              {
	            case EPgosPlayerDataDirtyFlags::Baisc:  
                   SyncPlayerBasicInfoToPgos();  
                   break;  
                case EPgosPlayerDataDirtyFlags::RoleAppearance:  
                   SyncRoleAppearanceToPgos();  
                   break;  
                case EPgosPlayerDataDirtyFlags::Clothes:  
                   SyncClothesToPgos();  
                   break;  
                case EPgosPlayerDataDirtyFlags::CompanyInfo:  
                   SyncCompanyInfoToPgos();  
                   break;  
                case EPgosPlayerDataDirtyFlags::FunctionUnlock:  
                   SyncFunctionUnlockToPgos();  
                   break;  
                case EPgosPlayerDataDirtyFlags::MissionFinished:  
                   SyncMissionFinishedInfosToPgos();  
                   break;  
                case EPgosPlayerDataDirtyFlags::AchievementProgress:  
                   SyncAchievementProgressToPgos();  
                   break;  
                default:  
                   UE_LOG(ServerPgosApi, Error, 
                   TEXT("no supported PgosPlayerDataDirtyFlag(%d)"), i);  
                   break;  
             }          
           }       
        }       
        PgosDataDirtyFlags.Reset();  
    }
}
```

由于每个数据分类里的数据都不一样，所以不能将一个PlayerState中的所有数据分类一起打包发送给PGOS。（一个玩家的所有数据）

但是可以将多个PlayerState中相同的数据分类打包发送给PGOS。（多个玩家的同类数据）

这是优化的方向。

```cpp
// 获取本DS上所有玩家的PlayerState，注意还要去掉AI角色
void AMyGameMode::HandleMatchHasStarted()
{
    for (APlayerState* PS : GameState->PlayerArray)
    {
        // 处理玩家
	    if (PS  && !PS->IsABot())
	    {
	    }`
    }
}

// 如果在其他地方写逻辑可以用：
UWorld* World = GetWorld();
if (!World) return;

AGameState* GameState = World->GetGameState();
if (!GameState) return;

for (APlayerState* PS : GameState->PlayerArray)
{
    if (PS  && !PS->IsABot())
    {
    }
}
```

## Pgos接口解析

> Plugins\PgosSDK\Source\PgosSDKCpp\Public\Core\PgosServerPlayerProfileAPI.h

```cpp
class FPgosPlayerProfileAPI
{
	GetPlayerInfo
	BatchGetPlayerInfo
	
	GetOneOfPlayerKVData  // Query the a kvdata of a player.
	GetPlayerKVData // Query kvdata map of a player.
	BatchGetPlayerKVData // Query kvdata map of many players.
	
	GetPlayerGroupKVData // Query a group kvdata of a player.
	BatchGetPlayerGroupKVData // batch query of a group KVData for multiple players
	
	SetOneOfPlayerKVData // player - k - v
	SetPlayerKVData // player - kvmap
	BatchSetPlayerKVData // array_of(player-kvmap)
	
	// 原子操作
	IncrOneOfPlayerKVData // player - k - inc_v
	BatchIncrOneOfPlayerKVData // player_array - k - inc_v
	IncrPlayerKVData // player - k_incv_map
	BatchIncrPlayerKVData // array_of(player-kvmap)
	BatchIncrPlayerKVDataIdempotent // 幂等版本的BatchIncrPlayerKVData  ？？？
	
	GetPlayerVersionedKVData // player - k_array
	BatchGetPlayerVersionedKVData // player_array - k_array
	SetPlayerVersionedKVData // player - key_array - version
	BatchSetPlayerVersionedKVData // array_of(player - key_array - version)
	
	BatchOpenIDToPlayerID // provicer - openid_array
}
```


