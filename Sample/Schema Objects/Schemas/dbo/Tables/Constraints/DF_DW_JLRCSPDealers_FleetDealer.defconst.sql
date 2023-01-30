ALTER TABLE [dbo].[DW_JLRCSPDealers]
   ADD CONSTRAINT [DF_DW_JLRCSPDealers_FleetDealer]
   DEFAULT 0
   FOR [FleetDealer]
