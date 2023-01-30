CREATE TABLE [NWB].[TargetServers]
(
	TargetServerName	NVARCHAR(512) NOT NULL,
	p_hubName			NVARCHAR(512) NOT NULL, 
	p_targetServerName	NVARCHAR(512) NOT NULL, 
	p_reRandomizeSortId	BIT  NOT NULL
)
