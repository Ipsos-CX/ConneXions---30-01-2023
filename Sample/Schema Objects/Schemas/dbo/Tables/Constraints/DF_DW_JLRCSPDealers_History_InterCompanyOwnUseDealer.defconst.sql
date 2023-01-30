ALTER TABLE [dbo].[DW_JLRCSPDealers_History]
   ADD CONSTRAINT [DF_DW_JLRCSPDealers_History_InterCompanyOwnUseDealer]
   DEFAULT 0
   FOR [InterCompanyOwnUseDealer]
