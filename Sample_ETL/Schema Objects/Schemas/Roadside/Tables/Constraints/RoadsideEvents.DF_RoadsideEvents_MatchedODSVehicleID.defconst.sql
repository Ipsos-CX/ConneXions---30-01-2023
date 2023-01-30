ALTER TABLE [Roadside].[RoadsideEvents]
   ADD CONSTRAINT [DF_RoadsideEvents_MatchedODSVehicleID] 
   DEFAULT 0
   FOR MatchedODSVehicleID;

