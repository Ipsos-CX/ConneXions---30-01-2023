ALTER TABLE [dbo].[DW_JLRCSPDealers]
   ADD CONSTRAINT [DF_DW_JLRCSPDealers_InterCompanyOwnUseDealer]
   DEFAULT 0
   FOR [InterCompanyOwnUseDealer]
