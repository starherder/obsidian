
## 说明

Pgos中的players/KV Data Template，用于记录玩家身上的数据

[PGOS Console Portal](https://cnsh.pgos.intlgame.cn/console.html#/console/playerDataTemplate?t=cnsh_4ntzr_349_dev)

![](https://wdcdn.qpic.cn/MTY4ODg1ODIyNTQxNDQwNA_459410_hksPc-ij30UuRz19_1780558274?w=2560&h=1229&type=image/png)

如果要增加删除KV数据，需要手动修改。

因为我们可以有很多个大区，玩家身上会有很多kv数据，为了批量修改，要使用官方提供的PgosCli工具。

## 下载

[PGOS Portal](https://pgos.intlgame.com/#/index/download?redirect=%2Findex%2Fwelcome)

![](https://wdcdn.qpic.cn/MTY4ODg1ODIyNTQxNDQwNA_367365_xDIBAXN6901-CFBa_1780558376?w=835&h=361&type=image/png)

## 脚本

将以下批处理脚本放到pgos_cli_v0.2.15\pgos_cli目录下

![[batch_set_kvdata.bat]]

![[del_kvdata_param.json]]

![[title_regions.txt]]

![[add_kvdata_param.json]]

### tile_regions.txt

用键值对的方法记录了所有需要处理的pgos大区

```json
BETA=cnsh_4ntzr_243_test
DESIGNER=cnsh_4ntzr_456_dev
DEV=cnsh_4ntzr_349_dev 
。。。
```

### add_kvdata_param.json

需要添加的kv数据的配置

```json
{  
	"Add": [    
		{      
			"Key": "TestTestTest",      
			"Type": "String",      
			"DefaultValue": "{}",      
			"ServerOnly": false,      
			"ClientWritable": false,      
			"ClientPublic": true,      
			"Versioned": false,      
			"Description": "set from cli"    
		}  
	],  
	"Update": [],  
	"Remove": []
}
```

如果需要添加多条kv数据，只要再Add中增加更多的条目即可。

### del_kvdata_param.json

需要删除掉的kv数据的配置

```json
{  
	"Add": [],  
	"Update": [],  
	"Remove": [ "TestTestTest" ]
}
```

如果要删除多条kv数据，只要将它们的key值记录到Remove项中即可。

### batch_set_kvdata.bat

执行此脚本即可批量增加、删除kv数据

用法：
新增：batch_set_kvdata.bat add_kvdata_param.json
删除：batch_set_kvdata.bat del_kvdata_param.json