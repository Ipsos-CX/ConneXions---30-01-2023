ALTER TABLE [Roadside].[RoadsideEvents]
   ADD CONSTRAINT [DF_RoadsideEvents_MatchedODSPartyID] 
   DEFAULT 0
   FOR MatchedODSPersonID;


