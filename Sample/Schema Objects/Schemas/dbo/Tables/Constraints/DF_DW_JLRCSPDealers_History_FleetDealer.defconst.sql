ALTER TABLE [dbo].[DW_JLRCSPDealers_History]
   ADD CONSTRAINT [DF_DW_JLRCSPDealers_History_FleetDealer]
   DEFAULT 0
   FOR [FleetDealer]
