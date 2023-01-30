CREATE NONCLUSTERED INDEX [IX_AdditionalInfoSales_EventID_LostLeads] 
	ON [Event].[AdditionalInfoSales] ([EventID]) 
	INCLUDE ([LostLead_CompleteSuppressionJLR], [LostLead_CompleteSuppressionRetailer], [LostLead_PermissionToEmailJLR], [LostLead_PermissionToEmailRetailer], [LostLead_PermissionToPhoneJLR], [LostLead_PermissionToPhoneRetailer], [LostLead_ConvertedDateOfLastContact], [LostLead_MarketingPermission])
