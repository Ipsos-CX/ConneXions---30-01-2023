CREATE PROCEDURE [Migration].[uspRoadsideNetworks]
AS


insert into Party.RoadsideNetworks (PartyIDFrom, 
									PartyIDTo, 
									RoleTypeIDFrom, 
									RoleTypeIDTo, 
									RoadsideNetworkCode, 
									FromDate, 
									RoadsideNetworkName)
values 
	(	8485987, 
		3, -- Land Rover
		50, -- Roadside Network
		7,  -- Manufacturer
		'GBR',
		getdate(),
		'Land Rover UK Roadside Assistance Network' 
	),
	(	8485988, 
		2, -- Jaguar
		50,  -- Roadside Network
		7,  -- Manufacturer
		'GBR',
		getdate(),
		'Jaguar UK Roadside Assistance Network'
	)