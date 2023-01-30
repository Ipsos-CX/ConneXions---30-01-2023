ALTER TABLE [UsableEmailReport].[Base] 
ADD  CONSTRAINT [DF_UsableEmailReport_Base_UsableFlag]  
DEFAULT ((0)) FOR [UsableFlag]

