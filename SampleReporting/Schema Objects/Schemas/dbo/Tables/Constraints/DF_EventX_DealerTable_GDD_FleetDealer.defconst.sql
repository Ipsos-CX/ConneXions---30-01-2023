ALTER TABLE [dbo].[EventX_DealerTable_GDD]
   ADD CONSTRAINT [DF_EventX_DealerTable_GDD_FleetDealer] 
   DEFAULT 'Non-Fleet Retailer'
   FOR FleetDealer


