ALTER DATABASE [$(DatabaseName)]
    ADD FILE (NAME = [SampleReporting_Data], FILENAME = 'D:\aa08.data01\SampleReporting_Data.mdf', SIZE = 219264 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 10 %) TO FILEGROUP [PRIMARY];

