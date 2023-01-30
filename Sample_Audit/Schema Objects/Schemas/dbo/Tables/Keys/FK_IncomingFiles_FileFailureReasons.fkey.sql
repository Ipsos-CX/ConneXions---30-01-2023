ALTER TABLE [dbo].[IncomingFiles]
	ADD CONSTRAINT [FK_IncomingFiles_FileFailureReasons] 
	FOREIGN KEY (FileLoadFailureID)
	REFERENCES [dbo].[FileFailureReasons] ([FileFailureID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

