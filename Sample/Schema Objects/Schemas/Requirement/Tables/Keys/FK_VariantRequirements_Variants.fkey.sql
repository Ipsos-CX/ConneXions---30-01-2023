ALTER TABLE [Requirement].[VariantRequirements]
	ADD CONSTRAINT [FK_VariantRequirements_Variants] 
	FOREIGN KEY (VariantID)
	REFERENCES Vehicle.ModelVariants (VariantID)	

