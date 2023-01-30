
create table [dbo].[CustomerEventList]
( 
		TransferPartyID			bigint			null,
		EventID					bigint			null,
		VehicleID				bigint			null,
		RegistrationID			bigint			null,
		CASEID					bigint			null,
		EventTypeID				bigint			null,
		VehicleRoleTypeID		bigint			null,
		OutletPartyID			bigint			null,
		OutletFunctionID		bigint			null,
		CustomerPartyID			bigint			null,
		ModelID					bigint			null,
		Market					nvarchar(255)	null,
		SuperNationalRegion		nvarchar(255)	null,
		SubNationalRegion		nvarchar(255)	null,
		TransferDealer			nvarchar(255)	null,
		EventTypeDesc			nvarchar(255)	null,
		RegNo					nvarchar(255)	null,
		VIN						nvarchar(255)	null,
		Customer				nvarchar(255)	null,
		OutletFunction			nvarchar(255)	null,
		Outlet					nvarchar(255)	null,
		VehicleRoleTypeDesc		nvarchar(255)	null,
		Model					nvarchar(255)	null,
		Selected				char(4)	default ' ',
		ReceivedDate			datetime		null,
		EventDate				datetime		null
)
GO