CREATE TABLE [LostLeads].[ModelVehicleMatchStrings]
(
	ModelVehicleMatchStringID			INT IDENTITY(1,1) NOT NULL, 
	ModelVehicleMatchString				NVARCHAR(200)  NOT NULL,
	VehicleID							dbo.VehicleID NOT NULL	
)
