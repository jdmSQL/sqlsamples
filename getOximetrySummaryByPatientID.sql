USE [InformaticsDataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[getOximetrySummaryByPatientID]    Script Date: 10/03/2016 12:16:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--CREATE procedure [dbo].[getOximetrySummaryByPatientID] (
--@StartDateParam datetime ,
--@EndDateParam datetime,
--@StartTimeParam varchar(20),
--@EndTimeParam varchar(20),
--@PatientID varchar(20)
--)

--CREATE procedure [dbo].[getOximetrySummaryByPatientID] (
--@StartDateParam varchar(20) = '2016-08-8',
--@EndDateParam varchar(20) = '2016-08-9',
--@StartTimeParam varchar(20) = '14:21:55.293',
--@EndTimeParam varchar(20) = '09:14:45.810',
--@PatientID varchar(20)  = 'RCraft'
--)


ALTER procedure [dbo].[getOximetrySummaryByPatientID] (
@StartDateParam datetime = '2/1/2016',
@EndDateParam datetime = '2/2/2016',
@StartTimeParam varchar(20) = '20:00',
@EndTimeParam varchar(20) = '08:00',
@PatientID varchar(20)  = '10094643177'
)

-- exec getOximetrySummaryByPatientID '2016/02/01', '2016/02/02', '20:00' , '08:00', '10094643177'

--DeviceMonitoringSessionId	StartMonitoring	PatientName	AltName	EndMonitoring
--268	2016-03-24 14:21:59.383	Craft, Rollin	RCraft	2016-03-24 14:24:22.320
--269	2016-03-24 14:24:32.173	Craft, Rollin	RCraft	2016-03-25 10:55:34.160
--271	2016-03-25 10:55:47.333	Craft, Rollin	RCraft	2016-03-25 15:31:03.047
--273	2016-03-25 15:31:09.783	Craft, Rollin	RCraft	2016-03-27 09:04:45.810
--@DeviceMonitoringSessionID int)
--2016-03-27 09:04:45.810
as
Begin
--   2016-01-05 13:51:38.653	2016-03-18 10:48:15.383

--2016-03-24 14:21:55.293	2016-03-24 14:24:22.293

-- combining the raw date with time inputs to make one Date & Time value for queries

Declare 
@StartDateTime as datetime, @EndDateTime as datetime, 
@StartDateTimeJoin as varchar(25),  @ConvertStartTimeToVarchar varchar(10),
@ConvertEndTimeToVarchar varchar(10),
@EndDateTimeJoin as varchar(25), @DeviceMonitoringSessionID int;


Set @ConvertStartTimeToVarchar = CONVERT(varchar(10), @StartDateParam, 111)
Set @ConvertEndTimeToVarchar = CONVERT(varchar(10), @EndDateParam, 111)

SET @StartDateTimeJoin = @ConvertStartTimeToVarchar  + ' ' + @StartTimeParam
SET @EndDateTimeJoin = @ConvertEndTimeToVarchar  + ' ' + @EndTimeParam

SET @StartDateTime =  (Select convert(datetime, @StartDateTimeJoin, 121)) -- yyyy-mm-dd hh:mm:ss.mmm
SET @EndDateTime =  (Select convert(datetime, @EndDateTimeJoin, 121)) -- yyyy-mm-dd hh:mm:ss.mmm

--SET @StartDateTime =  (Select convert(datetime, '2016-03-8 14:21:55.293', 121)) -- yyyy-mm-dd hh:mm:ss.mmm
--SET @EndDateTime =  (Select convert(datetime, '2016-03-27 09:14:45.810', 121)) -- yyyy-mm-dd hh:mm:ss.mmm

PRINT @ConvertStartTimeToVarchar
PRINT @ConvertEndTimeToVarchar

Print @StartDateParam  + ' ' + @StartTimeParam
Print @EndDateParam + ' ' + @EndTimeParam

PRINT @StartDateTimeJoin
PRINT @EndDateTimeJoin

PRINT @StartDateTime 
PRINT @EndDateTime 

--Test exec getOximetrySummaryByPatientID '2016-01-27 13:59:24.000','2016-01-27 14:25:53.000',233 ;

--Test exec getOximetrySummaryByPatientID '2016-03-15 13:51:38.653','2016-03-18 10:48:15.383',229 ;

--Test exec getOximetrySummaryByPatientID '2016-03-17 13:51:38.653','2016-03-18 10:48:15.383',229 ;

--Test exec getOximetrySummaryByPatientID '2016-02-25 10:12:25.770','2016-02-28 12:46:23.080',251 ;

--ExternalPatientIDs
--111111
--222222
--RC
--RCraft

-- Do an if exist on #SPO2... to drop before creating it


declare
@TimeRecording varchar(20),
@TimeExcludedSampling  varchar(20),
@TimeTotalValidSampling varchar(20),
--@DesaturationCountExclusions int,
--@DesaturationEvents int,
--@PatientID varchar(200),
--@DoctorName varchar(200),
@RecordingSeconds bigint,
@RecordingValidSeconds bigint,
@gap bigint = 10000,
@desaturation int = 4;
--PRINT 'RecordingSeconds'
----set @RecordingSeconds = DATEDIFF(SECOND, @StartDateTime, @EndDateTime);
--PRINT 'IN BETWEEN'

--PRINT 'JustafterRecordingSeconds'
----set @PatientID = 'Patient A';
----set @DoctorName = 'DoctorName';



	DECLARE @TmpDmsTbl AS TABLE (DeviceMonitoringSessionId INT NOT NULL, StartMonitoring DateTime NOT NULL, PatientName varchar(50), AltName varchar(50),  EndMonitoring DateTime )
	
	--Get all deviceMonitorSession for the patient and the device=	
	INSERT INTO @TmpDmsTbl
	SELECT DeviceMonitoringSessionId, StartMonitoring, LastName + ', ' + FirstName as PatientName, ExternalIdentity as AltName, EndMonitoring
	FROM PatientMonitoringSession pms with(nolock) 
		INNER JOIN Patient p with(nolock)
			ON pms.PatientId=p.PatientId
		INNER JOIN DeviceMonitoringSession dms with(nolock) 
			ON dms.PatientMonitoringSessionId=pms.PatientMonitoringSessionId 
		INNER JOIN DeviceType dt with(nolock) 
			ON dt.DeviceTypeId=dms.DeviceTypeId
		INNER JOIN DeviceCategory dc with(nolock) 
			ON dt.DeviceCategoryId=dc.DeviceCategoryID 

	--WHERE p.ExternalIdentity=@PatientExternalID
	--WHERE p.ExternalIdentity= 'RCraft'
	WHERE p.ExternalIdentity=@PatientID 
			AND dc.DeviceCategoryUniqueId in ('PulseOximeter', 'Capnography')
		--And EndMonitoring < @StartDateTime
		--And @EndDateTime > StartMonitoring 
		And EndMonitoring >= Convert(datetime, @StartDateTime)
		And StartMonitoring <= Convert(datetime, @EndDateTime)

DECLARE @PatientName as varchar(100);

Set @PatientName = (Select Top 1 PatientName from @TmpDmsTbl)


--PRINT 'Just below DMSTemp'

--Select * from @TmpDmsTbl

Declare @SessionIDCount int;

Set @SessionIDCount =  (Select Count(DeviceMonitoringSessionId) As SessionCount from @TmpDmsTbl)

PRINT @SessionIDCount

--Select * from DeviceMonitoringSession
--Select distinct DeviceMonitoringSessionID from dbo.IpiSpO2

--Select Min(RefTime) as BeginTime, MAX(Reftime) as EndTime from dbo.ipiSpO2 where DeviceMonitoringSessionID in 
--(268),
--269,
--271,
--273)

--268
--269
--271
--273

-- Obtain Beginning Time of actual monitoring session if startdate from report parameter is prior to actual data

	DECLARE @minFromTime DateTime
	SELECT @minFromTime = ( SELECT min(StartMonitoring) FROM @TmpDmsTbl )

--	SELECT @FromTime;
--	SELECT @ToTime;	
--	SELECT @minFromTime;
--PRINT 'just before the mintime'
	IF  ( @minFromTime > @StartDateTime )
	  SET @StartDateTime = @minFromTime ;
--PRINT 'just afer the mintime'
-- Obtain actual End Date from the data, in case end date parameter is greater than actual the last monitoring record

	  DECLARE @numUnfinished INT;
	SELECT @numUnfinished = ( SELECT count(DeviceMonitoringSessionId) FROM @TmpDmsTbl WHERE EndMonitoring is NULL )
--PRINT 'Just after the numunfinished'
--	SELECT @numUnfinished
	
	IF  ( 1 > @numUnfinished )
	BEGIN
		DECLARE @maxToTime DateTime;
		SELECT @maxToTime = ( SELECT max(EndMonitoring) FROM @TmpDmsTbl )
		IF  ( @maxToTime < @EndDateTime )
			SET @EndDateTime = @maxToTime ;
	END;
	
	--  Select * from dbo.Patient 

--Select @StartDateTime as 'StartAdjustedDate'
--Select @EndDateTime as 'EndAdjustedDate'

If @SessionIDCount > 0
BEGIN
set @RecordingSeconds = DATEDIFF(SECOND, @StartDateTime, @EndDateTime);
set @TimeRecording = dbo.getFormattedDurationString (@StartDateTime, @EndDateTime);
END
ELSE
BEGIN
set @RecordingSeconds = 0
set @TimeRecording = '00:00:00'
END



--PRINT @RecordingSeconds + 'Recording Seconds'

PRINT @TimeRecording + 'Total Time recording'
------------------------------------------------------------------------------
--
-- START PROCESSING SPO2 DATA
------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#SpO2') IS NOT NULL
   DROP TABLE #SpO2;

CREATE table #SpO2 
(
rownum  bigint,
[SpO2Value] float,
--[NextSpO2Value] float,
[RefTime] datetime,
ExcludedTime bigint
--[NextRefTime] datetime,
--[AbsoluteDuration] decimal(18,6),
--[AdjustedDuration] decimal(18,6),
--[IsGap] bit,
--[IsDesaturation] bit
);

Insert into #SpO2 
SELECT
	rownum = ROW_NUMBER() OVER (ORDER BY p.RefTime),
	p.SpO2Value,
	p.RefTime,
	NULL
FROM [dbo].[IpiSpO2] p  WITH (NOLOCK)
where DeviceMonitoringSessionID in  (Select DeviceMonitoringSessionID from @TmpDmsTbl)
	and  (RefTime >= @StartDateTime
	and RefTime <= @EndDateTime)
	--And p.SpO2Value IS NOT NULL
	Order by Reftime

CREATE NONCLUSTERED INDEX [IX_IpiSpO2_RowNumIndex] ON #SpO2
(
	rownum ASC

)

--PRINT 'JUst after the temp table'

IF OBJECT_ID('tempdb..#SPO2FullTable') IS NOT NULL
   DROP TABLE #SPO2FullTable;

	SELECT  
	sp.rownum,
	sp.SpO2Value,
	nex.SpO2Value NextSpO2Value,
	sp.RefTime RefTime,
	nex.RefTime NextRefTime,
	DATEDIFF ( ms ,  sp.RefTime,  nex.RefTime ) [AbsoluteDuration],
	DATEDIFF ( ms ,  sp.RefTime,  nex.RefTime ) [AdjustedDuration],
	case when DATEDIFF ( ms , sp.RefTime , nex.RefTime ) > @gap then 1 else 0 end IsGap,
	--case when c.SpO2Value - nex.SpO2Value >=  @desaturation then 1 else 0 end IsDesaturation,
	CASE WHEN sp.SpO2Value IS NULL THEN 1 else 0 END as ExcludedTime
	into #SPO2FullTable
FROM #SpO2 sp  WITH (NOLOCK)
LEFT JOIN #SpO2 nex  WITH (NOLOCK) ON nex.rownum = sp.rownum + 1;

--Select DeviceMonitoringSessionID from @TmpDmsTbl
--Select * from #SPO2FullTable

Declare @ValidTimeInSeconds bigint,  @ValidSPO2RecordingTime varchar(10), @TotalExcludedTimeinSeconds bigint, @TotalExcludedTime varchar(10);

Set @ValidTimeInSeconds = (Select (Sum(AdjustedDuration) / 1000) as ValidTime from #SPO2FullTable
Where IsGap = 0 and ExcludedTime = 0)

Set @TotalExcludedTimeinSeconds = (@RecordingSeconds - @ValidTimeInSeconds)

Set @TotalExcludedTime = dbo.getFormattedDurationStringFromSeconds(@TotalExcludedTimeinSeconds)

Set @ValidSPO2RecordingTime = dbo.getFormattedDurationStringFromSeconds(@ValidTimeInSeconds)

-- Establish the SPO2 Median

Declare @SPO2Median as float

SET @SPO2Median = (SELECT
(
 (SELECT MAX(SpO2Value) FROM
   (SELECT TOP 50 PERCENT SpO2Value FROM #SPO2FullTable Where (IsGap = 0 or ExcludedTime = 0)  ORDER BY SpO2Value) AS BottomHalf)
 +
 (SELECT MIN(SpO2Value) FROM
   (SELECT TOP 50 PERCENT SpO2Value FROM #SPO2FullTable Where (IsGap = 0 or ExcludedTime = 0)  ORDER BY SpO2Value DESC) AS TopHalf)
) / 2 AS Median    )


------------------------------------------------------------------------------
--
-- END PROCESSING SPO2 DATA
------------------------------------------------------------------------------


----  BEGIN SECTION FOR PULSE DATA   ---------------

IF OBJECT_ID('tempdb..#PulseRate') IS NOT NULL
   DROP TABLE #PulseRate;

CREATE table #PulseRate 
(
rownum  bigint,
[Value] float,
--[NextSpO2Value] float,
[RefTime] datetime,
ExcludedTime bigint
--[NextRefTime] datetime,
--[AbsoluteDuration] decimal(18,6),
--[AdjustedDuration] decimal(18,6),
--[IsGap] bit,
--[IsDesaturation] bit
);

Insert into #PulseRate 
SELECT
	rownum = ROW_NUMBER() OVER (ORDER BY p.RefTime),
	p.Value,
	p.RefTime,
	NULL
FROM [dbo].[IpiPulseRate] p  WITH (NOLOCK)
where DeviceMonitoringSessionID in  (Select DeviceMonitoringSessionID from @TmpDmsTbl)
	and  (RefTime >= @StartDateTime
	and RefTime <= @EndDateTime)
	--And p.Value IS NOT NULL
	Order by Reftime

CREATE NONCLUSTERED INDEX [IX_IpiPulseRate_RowNumIndex] ON #PulseRate
(
	rownum ASC

)

--PRINT 'JUst after the temp table'

IF OBJECT_ID('tempdb..#PulseRateFullTable') IS NOT NULL
   DROP TABLE #PulseRateFullTable;

	SELECT  
	pr.rownum,
	pr.Value as PulseValue,
	nex.Value NextPulseRateValue,
	pr.RefTime RefTime,
	nex.RefTime NextRefTime,
	DATEDIFF ( ms ,  pr.RefTime,  nex.RefTime ) [AbsoluteDuration],
	DATEDIFF ( ms ,  pr.RefTime,  nex.RefTime ) [AdjustedDuration],
	case when DATEDIFF ( ms , pr.RefTime , nex.RefTime ) > @gap then 1 else 0 end IsGap,	
	--case when c.SpO2Value - nex.SpO2Value >=  @desaturation then 1 else 0 end IsDesaturation,
	CASE WHEN pr.Value IS NULL THEN 1 else 0 END as ExcludedTime
	into #PulseRateFullTable
FROM #PulseRate pr  WITH (NOLOCK)
LEFT JOIN #PulseRate nex  WITH (NOLOCK) ON nex.rownum = pr.rownum + 1;


CREATE NONCLUSTERED INDEX [IX_IpiPulseRateFullTable_RowNumIndex] ON #PulseRateFulltable
(
	rownum ASC

)

Declare @ValidPulseTimeInSeconds bigint,  @ValidPulseRecordingTime varchar(10)  ;

Set @ValidPulseTimeInSeconds = (Select (Sum(AdjustedDuration) / 1000) as ValidTime from #PulseRateFullTable
Where IsGap = 0 and ExcludedTime = 0)

--Set @TotalExcludedTimeinSeconds = (@RecordingSeconds - @ValidTimeInSeconds)

--Set @TotalExcludedTime = dbo.getFormattedDurationStringFromSeconds(@TotalExcludedTimeinSeconds)

Set @ValidPulseRecordingTime = dbo.getFormattedDurationStringFromSeconds(@ValidPulseTimeInSeconds)

-- Establish the Pulse Median

Declare @PulseRateMedian as float

SET @PulseRateMedian = (SELECT
(
 (SELECT MAX(PulseValue) FROM
   (SELECT TOP 50 PERCENT PulseValue FROM #PulseRateFullTable Where (IsGap = 0 or ExcludedTime = 0)  ORDER BY PulseValue) AS BottomHalf)
 +
 (SELECT MIN(PulseValue) FROM
   (SELECT TOP 50 PERCENT PulseValue FROM #PulseRateFullTable Where (IsGap = 0 or ExcludedTime = 0)  ORDER BY PulseValue DESC) AS TopHalf)
) / 2 AS Median    ) 

----  END SECTION FOR PULSE DATA  ------------------

----  BEGIN SECTION FOR ETCO2 DATA -----------------

IF OBJECT_ID('tempdb..#EtCO2') IS NOT NULL
   DROP TABLE #EtCO2;

CREATE table #EtCO2 
(
rownum  bigint,
[EndTidalCO2] float,
[InCO2] float,
[RefTime] datetime,
ExcludedTime bigint
--[NextRefTime] datetime,
--[AbsoluteDuration] decimal(18,6),
--[AdjustedDuration] decimal(18,6),
--[IsGap] bit,
--[IsDesaturation] bit
);

Insert into #EtCO2 
SELECT
	rownum = ROW_NUMBER() OVER (ORDER BY et.RefTime),
	et.EndTidalCO2,
	et.[FractionalConcentrationOfInspiredCO2] as InCO2,
	et.RefTime,
	NULL
FROM [dbo].[IpiCapnography] et  WITH (NOLOCK)
where DeviceMonitoringSessionID in  (Select DeviceMonitoringSessionID from @TmpDmsTbl)
	and  (RefTime >= @StartDateTime
	and RefTime <= @EndDateTime)
	--And et.EndTidalCO2 IS NOT NULL
	Order by Reftime

CREATE NONCLUSTERED INDEX [IX_IpiEtCO2_RowNumIndex] ON #EtCO2
(
	rownum ASC

)

--PRINT 'JUst after the temp table'

IF OBJECT_ID('tempdb..#EtCO2FullTable') IS NOT NULL
   DROP TABLE #EtCO2FullTable;

	SELECT  
	et.rownum,
	et.EndTidalCO2 as EtCO2Value,
	et.InCO2 as InCO2Value,
	nex.EndTidalCO2 NextEtCO2Value,
	et.RefTime RefTime,
	nex.RefTime NextRefTime,
	DATEDIFF ( ms ,  et.RefTime,  nex.RefTime ) [AbsoluteDuration],
	DATEDIFF ( ms ,  et.RefTime,  nex.RefTime ) [AdjustedDuration],
	case when DATEDIFF ( ms , et.RefTime , nex.RefTime ) > @gap then 1 else 0 end IsGap,	
	--case when c.SpO2Value - nex.SpO2Value >=  @desaturation then 1 else 0 end IsDesaturation,
	CASE WHEN et.[EndTidalCO2] IS NULL THEN 1 else 0 END as ExcludedTime
	into #EtCO2FullTable
FROM #EtCO2 et  WITH (NOLOCK)
LEFT JOIN #EtCO2 nex  WITH (NOLOCK) ON nex.rownum = et.rownum + 1;


CREATE NONCLUSTERED INDEX [IX_IpiEtCO2FullTable_RowNumIndex] ON #EtCO2FullTable
(
	rownum ASC

)

-- Get FiCO2 Data

Select InCO2Value, AdjustedDuration, IsGap, 
CASE WHEN InCO2Value IS NULL THEN 1 else 0 END as ExcludedTime
 into #INCO2FullTable FROM #EtCO2FullTable

Declare @ValidInCO2TimeInSeconds bigint,  @ValidInCO2RecordingTime varchar(10)  ;

Set @ValidInCO2TimeInSeconds = (Select (Sum(AdjustedDuration) / 1000) as ValidTime from #INCO2FullTable
Where IsGap = 0 and ExcludedTime = 0)

--Set @TotalExcludedTimeinSeconds = (@RecordingSeconds - @ValidTimeInSeconds)

--Set @TotalExcludedTime = dbo.getFormattedDurationStringFromSeconds(@TotalExcludedTimeinSeconds)

Set @ValidInCO2RecordingTime = dbo.getFormattedDurationStringFromSeconds(@ValidInCO2TimeInSeconds)


Declare @ValidEtCO2TimeInSeconds bigint,  @ValidEtCO2RecordingTime varchar(10)  ;

Set @ValidEtCO2TimeInSeconds = (Select (Sum(AdjustedDuration) / 1000) as ValidTime from #EtCO2FullTable
Where IsGap = 0 and ExcludedTime = 0)

--Set @TotalExcludedTimeinSeconds = (@RecordingSeconds - @ValidTimeInSeconds)

--Set @TotalExcludedTime = dbo.getFormattedDurationStringFromSeconds(@TotalExcludedTimeinSeconds)

Set @ValidEtCO2RecordingTime = dbo.getFormattedDurationStringFromSeconds(@ValidEtCO2TimeInSeconds)

-- Establish the Pulse Median

Declare @EtCO2Median as float, @MAXInCO2 as float, @AVGInCO2 as float;

SET @EtCO2Median = (SELECT
(
 (SELECT MAX(EtCO2Value) FROM
   (SELECT TOP 50 PERCENT EtCO2Value FROM #EtCO2FullTable Where (IsGap = 0 or ExcludedTime = 0)  ORDER BY EtCO2Value) AS BottomHalf)
 +
 (SELECT MIN(EtCO2Value) FROM
   (SELECT TOP 50 PERCENT EtCO2Value FROM #EtCO2FullTable Where (IsGap = 0 or ExcludedTime = 0)  ORDER BY EtCO2Value DESC) AS TopHalf)
) / 2 AS Median    ) 

-- Stick this in overall cross tab query at the bottom.
--Select MAX(InCO2Value), AVG(InCO2Value) from #EtCO2FullTable Where IsGap = 0 and ExcludedTime = 0

--Select * from #EtCO2FullTable

----  END SECTION FOR ETCO2 DATA -------------------

----  BEGIN SECTION FOR RESPIRATION RATE DATA -----------------

IF OBJECT_ID('tempdb..#RespRate') IS NOT NULL
   DROP TABLE #RespRate;

CREATE table #RespRate 
(
rownum  bigint,
[Value] float,
[RefTime] datetime,
ExcludedTime bigint
--[NextRefTime] datetime,
--[AbsoluteDuration] decimal(18,6),
--[AdjustedDuration] decimal(18,6),
--[IsGap] bit,
--[IsDesaturation] bit
);

Insert into #RespRate 
SELECT
	rownum = ROW_NUMBER() OVER (ORDER BY rr.RefTime),
	rr.Value,
	rr.RefTime,
	NULL
FROM [dbo].[IpiRespirationRate] rr  WITH (NOLOCK)
where DeviceMonitoringSessionID in  (Select DeviceMonitoringSessionID from @TmpDmsTbl)
	and  (RefTime >= @StartDateTime
	and RefTime <= @EndDateTime)
	--And rr.Value IS NOT NULL
	Order by Reftime

CREATE NONCLUSTERED INDEX [IX_RespRate_RowNumIndex] ON #RespRate
(
	rownum ASC

)

--PRINT 'JUst after the temp table'

IF OBJECT_ID('tempdb..#RespRateFullTable') IS NOT NULL
   DROP TABLE #RespRateFullTable;

	SELECT  
	rr.rownum,
	rr.Value as RespRateValue,
	nex.Value NextRespRateValue,
	rr.RefTime RefTime,
	nex.RefTime NextRefTime,
	DATEDIFF ( ms ,  rr.RefTime,  nex.RefTime ) [AbsoluteDuration],
	DATEDIFF ( ms ,  rr.RefTime,  nex.RefTime ) [AdjustedDuration],
	case when DATEDIFF ( ms , rr.RefTime , nex.RefTime ) > @gap then 1 else 0 end IsGap,	
	--case when c.SpO2Value - nex.SpO2Value >=  @desaturation then 1 else 0 end IsDesaturation,
	CASE WHEN rr.[Value] IS NULL THEN 1 else 0 END as ExcludedTime
	into #RespRateFullTable
FROM #RespRate rr  WITH (NOLOCK)
LEFT JOIN #RespRate nex  WITH (NOLOCK) ON nex.rownum = rr.rownum + 1;

CREATE NONCLUSTERED INDEX [IX_RespRateFullTable_RowNumIndex] ON #RespRateFullTable
(
	rownum ASC

)

Declare @ValidRespRateTimeInSeconds bigint,  @ValidRespRateRecordingTime varchar(10)  ;

Set @ValidRespRateTimeInSeconds = (Select (Sum(AdjustedDuration) / 1000) as ValidTime from #RespRateFullTable
Where IsGap = 0 and ExcludedTime = 0)

--Set @TotalExcludedTimeinSeconds = (@RecordingSeconds - @ValidTimeInSeconds)

--Set @TotalExcludedTime = dbo.getFormattedDurationStringFromSeconds(@TotalExcludedTimeinSeconds)

Set @ValidRespRateRecordingTime = dbo.getFormattedDurationStringFromSeconds(@ValidRespRateTimeInSeconds)

-- Establish the Pulse Median

Declare @RespRateMedian as float;

SET @RespRateMedian = (SELECT
(
 (SELECT MAX(RespRateValue) FROM
   (SELECT TOP 50 PERCENT RespRateValue FROM #RespRateFullTable Where (IsGap = 0 or ExcludedTime = 0)  ORDER BY RespRateValue) AS BottomHalf)
 +
 (SELECT MIN(RespRateValue) FROM
   (SELECT TOP 50 PERCENT RespRateValue FROM #RespRateFullTable Where (IsGap = 0 or ExcludedTime = 0)  ORDER BY RespRateValue DESC) AS TopHalf)
) / 2 AS Median    ) 


----  END  SECTION FOR RESPIRATION RATE DATA -----------------

----  BEGIN SECTION FOR INCO2 DATA -----------------

-- Verify if needed  (INcluded in ETCO2 section?)

----  END SECTION FOR INCO2 DATA -----------------


--Select * from  #SPO2 

 -- Select Sum(AbsoluteDuration) from  #SPO2FullTable  WHERE IsGap =  1
 --  Test select statement built for eventual update to exclude records by reftime from AlarmInstance Table.
 --Select * from #SPO2FullTable
 --inner join [dbo].[AlarmInstance] ON
 --[dbo].[AlarmInstance].StartTime <= #SPO2FullTable.RefTime
 --And NextRefTime <= [dbo].[AlarmInstance].EndTime
 --AND DeviceMonitoringSessionID = @DeviceMonitoringSessionID
 --And AlarmTypeDefinitionID in (30,73,74,89,90)


declare @results table (
RecordingSeconds bigint,
TotalTimeRecording varchar(20),
PatientID varchar(200),
PatientName varchar(100),
DoctorName varchar(200),
TimeExcludedSampling varchar(20),

PulseHighest decimal(10,1),
PulseLowest decimal(10,1),
PulseMean decimal(10,1),
PulseSD decimal(10,1),
PulseMedian float,
PulseValidTime varchar(20),


TimePulseGreater200  varchar(20),
pctPulseGreater200  decimal(10,1),

TimePulseBetween175_200  varchar(20), 
pctPulseBetween175_200  decimal(10,1),

TimePulseBetween150_174  varchar(20),
pctPulseBetween150_174  decimal(10,1), 

TimePulseBetween125_149  varchar(20),
pctPulseBetween125_149  decimal(10,1),

TimePulseBetween100_124  varchar(20), 
pctPulseBetween100_124  decimal(10,1),

TimePulseBetween75_99  varchar(20), 
pctPulseBetween75_99  decimal(10,1),

TimePulseBetween50_74  varchar(20),
pctPulseBetween50_74  decimal(10,1),

TimePulseBetween40_49  varchar(20),
pctPulseBetween40_49  decimal(10,1),

TimePulseBetween20_39  varchar(20),
pctPulseBetween20_39  decimal(10,1),

TimePulseLess20  varchar(20),
pctPulseLess20  decimal(10,1),



--Begin ETCO2 Section

EtCO2Highest decimal(10,1),
EtCO2Lowest decimal(10,1),
EtCO2Mean decimal(10,1),
EtCO2SD decimal(10,1),
EtCO2Median float,
EtCO2ValidTime varchar(20),
InCO2Highest   decimal(10,1),
InCO2Mean  decimal(10,1),
InCO2ValidTime varchar(20),

TimeETCO2Greater70  varchar(20), 
pctETCO2Greater70  decimal(10,1),

TimeETCO2Between61_70  varchar(20),  
pctETCO2Between61_70  decimal(10,1),

TimeETCO2Between51_60  varchar(20),  
pctETCO2Between51_60  decimal(10,1),

TimeETCO2Between46_50  varchar(20), 
pctETCO2Between46_50  decimal(10,1),

TimeETCO2Between41_45  varchar(20), 
pctETCO2Between41_45  decimal(10,1),

TimeETCO2Between36_40  varchar(20), 
pctETCO2Between36_40  decimal(10,1),

TimeETCO2Between30_35  varchar(20), 
pctETCO2Between30_35  decimal(10,1),

TimeETCO2Between20_29  varchar(20), 
pctETCO2Between20_29  decimal(10,1),

TimeETCO2Between10_19  varchar(20), 
pctETCO2Between10_19  decimal(10,1),

TimeETCO2Less10  varchar(20), 
pctETCO2Less10  decimal(10,1),


--End ETCO2 Section

SpO2Highest decimal(10,1),
SpO2Lowest decimal(10,1),
SpO2Mean decimal(10,1),
SpO2Median float,
SpO2SD decimal(10,1),
SPO2ValidTime varchar(20),
--

-- Begin Respiration Rate Section

RespRateHighest decimal(10,1),
RespRateLowest decimal(10,1),
RespRateMean decimal(10,1),
RespRateMedian float,
RespRateSD decimal(10,1),
RespRateValidTime varchar(20),


TimeRespRateGreater70  varchar(20),
pctRespRateGreater70  decimal(10,1),

TimeRespRateBetween61_70  varchar(20), 
pctRespRateBetween61_70  decimal(10,1),

TimeRespRateBetween51_60  varchar(20), 
pctRespRateBetween51_60  decimal(10,1),

TimeRespRateBetween41_50  varchar(20), 
pctRespRateBetween41_50  decimal(10,1),

TimeRespRateBetween31_40  varchar(20), 
pctRespRateBetween31_40  decimal(10,1),

TimeRespRateBetween21_30  varchar(20), 
pctRespRateBetween21_30  decimal(10,1),

TimeRespRateBetween16_20  varchar(20), 
pctRespRateBetween16_20  decimal(10,1),

TimeRespRateBetween11_15  varchar(20), 
pctRespRateBetween11_15  decimal(10,1),

TimeRespRateBetween6_10  varchar(20), 
pctRespRateBetween6_10  decimal(10,1),

TimeRespRateLess6  varchar(20), 
pctRespRateLess6  decimal(10,1),


-- End Respiration Rate Section


-- The next thirty columns will have a breakout by SPO2 value from 98 to 70


TimeSpO2gt98 varchar(20),
pctSpO2gt98 decimal(10,1),

TimeSpO2equal98 varchar(20),
pctSpO2equal98 decimal(10,1),

TimeSpO2equal97 varchar(20),
pctSpO2equal97 decimal(10,1),

TimeSpO2equal96 varchar(20),
pctSpO2equal96 decimal(10,1),

TimeSpO2equal95 varchar(20),
pctSpO2equal95 decimal(10,1),

TimeSpO2equal94 varchar(20),
pctSpO2equal94 decimal(10,1),

TimeSpO2equal93 varchar(20),
pctSpO2equal93 decimal(10,1),

TimeSpO2equal92 varchar(20),
pctSpO2equal92 decimal(10,1),

TimeSpO2equal91 varchar(20),
pctSpO2equal91 decimal(10,1),

TimeSpO2equal90 varchar(20),
pctSpO2equal90 decimal(10,1),

TimeSpO2equal89 varchar(20),
pctSpO2equal89 decimal(10,1),

TimeSpO2equal88 varchar(20),
pctSpO2equal88 decimal(10,1),

TimeSpO2equal87 varchar(20),
pctSpO2equal87 decimal(10,1),

TimeSpO2equal86 varchar(20),
pctSpO2equal86 decimal(10,1),

TimeSpO2equal85 varchar(20),
pctSpO2equal85 decimal(10,1),

TimeSpO2equal84 varchar(20),
pctSpO2equal84 decimal(10,1),

TimeSpO2equal83 varchar(20),
pctSpO2equal83 decimal(10,1),

TimeSpO2equal82 varchar(20),
pctSpO2equal82 decimal(10,1),

TimeSpO2equal81 varchar(20),
pctSpO2equal81 decimal(10,1),

TimeSpO2equal80 varchar(20),
pctSpO2equal80 decimal(10,1),

TimeSpO2equal79 varchar(20),
pctSpO2equal79 decimal(10,1),

TimeSpO2equal78 varchar(20),
pctSpO2equal78 decimal(10,1),

TimeSpO2equal77 varchar(20),
pctSpO2equal77 decimal(10,1),

TimeSpO2equal76 varchar(20),
pctSpO2equal76 decimal(10,1),

TimeSpO2equal75 varchar(20),
pctSpO2equal75 decimal(10,1),

TimeSpO2equal74 varchar(20),
pctSpO2equal74 decimal(10,1),

TimeSpO2equal73 varchar(20),
pctSpO2equal73 decimal(10,1),

TimeSpO2equal72 varchar(20),
pctSpO2equal72 decimal(10,1),

TimeSpO2equal71 varchar(20),
pctSpO2equal71 decimal(10,1),

TimeSpO2equal70 varchar(20),
pctSpO2equal70 decimal(10,1),


TimeSpO2lt90 varchar(20),
pctSpO2lt90 decimal(10,1),
TimeSpO2lt80 varchar(20),
pctSpO2lt80 decimal(10,1),
TimeSpO2lt70 varchar(20),
pctSpO2lt70 decimal(10,1),
TimeSpO2lt60 varchar(20),
pctSpO2lt60 decimal(10,1),
TimeSpO2lt89 varchar(20),
pctSpO2lt89 decimal(10,1),
TimeLessThan89 varchar(200),
TimeSpO2lgte90 varchar(20),
pctSpO2lgte90 decimal(10,1),
TimeSpO2lgte80lt90 varchar(20),
pctSpO2lgte80lt90 decimal(10,1),
TimeSpO2lgte70lt80 varchar(20),
pctSpO2lgte70lt80 decimal(10,1),
TimeSpO2lgte60lt70 varchar(20),
pctSpO2lgte60lt70 decimal(10,1));

insert into @results
(
RecordingSeconds,
TotalTimeRecording,
PatientID,
PatientName,
--DoctorName,
TimeExcludedSampling,

PulseHighest, 
PulseLowest, 
PulseMean, 
PulseSD,
PulseMedian,
PulseValidTime,

TimePulseGreater200, 
pctPulseGreater200,

TimePulseBetween175_200, 
pctPulseBetween175_200, 

TimePulseBetween150_174, 
pctPulseBetween150_174, 

TimePulseBetween125_149, 
pctPulseBetween125_149,

TimePulseBetween100_124, 
pctPulseBetween100_124,

TimePulseBetween75_99, 
pctPulseBetween75_99,

TimePulseBetween50_74, 
pctPulseBetween50_74,

TimePulseBetween40_49, 
pctPulseBetween40_49,

TimePulseBetween20_39, 
pctPulseBetween20_39,

TimePulseLess20, 
pctPulseLess20,


--EtCO2 section

EtCO2Highest,
EtCO2Lowest, 
EtCO2Mean, 
EtCO2SD, 
EtCO2Median, 
EtCO2ValidTime, 
InCO2Highest,
InCO2Mean,
InCO2ValidTime,


TimeETCO2Greater70, 
pctETCO2Greater70,

TimeETCO2Between61_70, 
pctETCO2Between61_70, 

TimeETCO2Between51_60, 
pctETCO2Between51_60, 

TimeETCO2Between46_50, 
pctETCO2Between46_50, 

TimeETCO2Between41_45, 
pctETCO2Between41_45, 

TimeETCO2Between36_40, 
pctETCO2Between36_40, 

TimeETCO2Between30_35, 
pctETCO2Between30_35, 

TimeETCO2Between20_29, 
pctETCO2Between20_29, 

TimeETCO2Between10_19, 
pctETCO2Between10_19, 

TimeETCO2Less10, 
pctETCO2Less10, 

--End EtCO2 Section

SpO2Highest,
SpO2Lowest,
SpO2Mean,
SpO2Median,
SpO2SD,
SPO2ValidTime,
--

RespRateHighest ,
RespRateLowest ,
RespRateMean ,
RespRateMedian ,
RespRateSD ,
RespRateValidTime,


TimeRespRateGreater70, 
pctRespRateGreater70,

TimeRespRateBetween61_70, 
pctRespRateBetween61_70, 

TimeRespRateBetween51_60, 
pctRespRateBetween51_60, 

TimeRespRateBetween41_50, 
pctRespRateBetween41_50, 

TimeRespRateBetween31_40, 
pctRespRateBetween31_40, 

TimeRespRateBetween21_30, 
pctRespRateBetween21_30, 

TimeRespRateBetween16_20, 
pctRespRateBetween16_20, 

TimeRespRateBetween11_15, 
pctRespRateBetween11_15, 

TimeRespRateBetween6_10, 
pctRespRateBetween6_10, 

TimeRespRateLess6, 
pctRespRateLess6, 

-- End RespReate

TimeSpO2gt98,
pctSpO2gt98,

TimeSpO2equal98 ,
pctSpO2equal98 ,

TimeSpO2equal97 ,
pctSpO2equal97 ,

TimeSpO2equal96 ,
pctSpO2equal96 ,

TimeSpO2equal95,
pctSpO2equal95 ,

TimeSpO2equal94 ,
pctSpO2equal94 ,

TimeSpO2equal93 ,
pctSpO2equal93 ,

TimeSpO2equal92 ,
pctSpO2equal92 ,

TimeSpO2equal91 ,
pctSpO2equal91 ,

TimeSpO2equal90 ,
pctSpO2equal90 ,

TimeSpO2equal89 ,
pctSpO2equal89 ,

TimeSpO2equal88 ,
pctSpO2equal88 ,

TimeSpO2equal87 ,
pctSpO2equal87 ,

TimeSpO2equal86 ,
pctSpO2equal86 ,

TimeSpO2equal85 ,
pctSpO2equal85 ,

TimeSpO2equal84 ,
pctSpO2equal84 ,

TimeSpO2equal83 ,
pctSpO2equal83 ,

TimeSpO2equal82 ,
pctSpO2equal82 ,

TimeSpO2equal81 ,
pctSpO2equal81 ,

TimeSpO2equal80 ,
pctSpO2equal80 ,

TimeSpO2equal79,
pctSpO2equal79 ,

TimeSpO2equal78 ,
pctSpO2equal78,

TimeSpO2equal77 ,
pctSpO2equal77 ,

TimeSpO2equal76 ,
pctSpO2equal76 ,

TimeSpO2equal75 ,
pctSpO2equal75 ,

TimeSpO2equal74 ,
pctSpO2equal74 ,

TimeSpO2equal73 ,
pctSpO2equal73 ,

TimeSpO2equal72 ,
pctSpO2equal72 ,

TimeSpO2equal71 ,
pctSpO2equal71 ,

TimeSpO2equal70 ,
pctSpO2equal70 ,


TimeSpO2lt90, 
pctSpO2lt90,
TimeSpO2lt80, 
pctSpO2lt80,
TimeSpO2lt70, 
pctSpO2lt70,
TimeSpO2lt60, 
pctSpO2lt60,
TimeSpO2lt89, 
pctSpO2lt89,
TimeLessThan89,
TimeSpO2lgte90, 
pctSpO2lgte90,
TimeSpO2lgte80lt90, 
pctSpO2lgte80lt90,
TimeSpO2lgte70lt80, 
pctSpO2lgte70lt80,
TimeSpO2lgte60lt70, 
pctSpO2lgte60lt70
--
)
select
@RecordingSeconds RecordingSeconds,
@TimeRecording TotalTimeRecording,
@PatientID PatientID,
@PatientName PatientName,
--@DoctorName DoctorName,
@TotalExcludedTime TimeExcludedSampling,
--@TimeTotalValidSampling TimeTotalValidSampling,

PulseHighest, 
PulseLowest, 
PulseMean, 
PulseSD,
PulseMedian,
PulseValidTime,

TimePulseGreater200, 
pctPulseGreater200,

TimePulseBetween175_200, 
pctPulseBetween175_200, 

TimePulseBetween150_174, 
pctPulseBetween150_174, 

TimePulseBetween125_149, 
pctPulseBetween125_149,

TimePulseBetween100_124, 
pctPulseBetween100_124,

TimePulseBetween75_99, 
pctPulseBetween75_99,

TimePulseBetween50_74, 
pctPulseBetween50_74,

TimePulseBetween40_49, 
pctPulseBetween40_49,

TimePulseBetween20_39, 
pctPulseBetween20_39,

TimePulseLess20, 
pctPulseLess20,



-- EtCO2
EtCO2Highest,
EtCO2Lowest, 
EtCO2Mean, 
EtCO2SD, 
EtCO2Median, 
EtCO2ValidTime, 
InCO2Highest,
InCO2Mean,
InCO2ValidTime,


TimeETCO2Greater70, 
pctETCO2Greater70,

TimeETCO2Between61_70, 
pctETCO2Between61_70, 

TimeETCO2Between51_60, 
pctETCO2Between51_60, 

TimeETCO2Between46_50, 
pctETCO2Between46_50, 

TimeETCO2Between41_45, 
pctETCO2Between41_45, 

TimeETCO2Between36_40, 
pctETCO2Between36_40, 

TimeETCO2Between30_35, 
pctETCO2Between30_35, 

TimeETCO2Between20_29, 
pctETCO2Between20_29, 

TimeETCO2Between10_19, 
pctETCO2Between10_19, 

TimeETCO2Less10, 
pctETCO2Less10, 


-- EtCO2
SpO2Highest,
SpO2Lowest,
SpO2Mean,
SPO2Median,
SpO2SD,
SPO2ValidTime,

--RespRate

RespRateHighest ,
RespRateLowest ,
RespRateMean ,
RespRateMedian ,
RespRateSD ,
RespRateValidTime,


TimeRespRateGreater70, 
pctRespRateGreater70,

TimeRespRateBetween61_70, 
pctRespRateBetween61_70, 

TimeRespRateBetween51_60, 
pctRespRateBetween51_60, 

TimeRespRateBetween41_50, 
pctRespRateBetween41_50, 

TimeRespRateBetween31_40, 
pctRespRateBetween31_40, 

TimeRespRateBetween21_30, 
pctRespRateBetween21_30, 

TimeRespRateBetween16_20, 
pctRespRateBetween16_20, 

TimeRespRateBetween11_15, 
pctRespRateBetween11_15, 

TimeRespRateBetween6_10, 
pctRespRateBetween6_10, 

TimeRespRateLess6, 
pctRespRateLess6, 

--


TimeSpO2gt98,
pctSpO2gt98,

TimeSpO2equal98 ,
pctSpO2equal98 ,

TimeSpO2equal97 ,
pctSpO2equal97 ,

TimeSpO2equal96 ,
pctSpO2equal96 ,

TimeSpO2equal95,
pctSpO2equal95 ,

TimeSpO2equal94 ,
pctSpO2equal94 ,

TimeSpO2equal93 ,
pctSpO2equal93 ,

TimeSpO2equal92 ,
pctSpO2equal92 ,

TimeSpO2equal91 ,
pctSpO2equal91 ,

TimeSpO2equal90 ,
pctSpO2equal90 ,

TimeSpO2equal89 ,
pctSpO2equal89 ,

TimeSpO2equal88 ,
pctSpO2equal88 ,

TimeSpO2equal87 ,
pctSpO2equal87 ,

TimeSpO2equal86 ,
pctSpO2equal86 ,

TimeSpO2equal85 ,
pctSpO2equal85 ,

TimeSpO2equal84 ,
pctSpO2equal84 ,

TimeSpO2equal83 ,
pctSpO2equal83 ,

TimeSpO2equal82 ,
pctSpO2equal82 ,

TimeSpO2equal81 ,
pctSpO2equal81 ,

TimeSpO2equal80 ,
pctSpO2equal80 ,

TimeSpO2equal79,
pctSpO2equal79 ,

TimeSpO2equal78 ,
pctSpO2equal78,

TimeSpO2equal77 ,
pctSpO2equal77 ,

TimeSpO2equal76 ,
pctSpO2equal76 ,

TimeSpO2equal75 ,
pctSpO2equal75 ,

TimeSpO2equal74 ,
pctSpO2equal74 ,

TimeSpO2equal73 ,
pctSpO2equal73 ,

TimeSpO2equal72 ,
pctSpO2equal72 ,

TimeSpO2equal71 ,
pctSpO2equal71 ,

TimeSpO2equal70 ,
pctSpO2equal70 ,

-------------------


TimeSpO2lt90, 
pctSpO2lt90,
TimeSpO2lt80, 
pctSpO2lt80,
TimeSpO2lt70, 
pctSpO2lt70,
TimeSpO2lt60, 
pctSpO2lt60,
TimeSpO2lt89, 
pctSpO2lt89,
TimeLessThan89,
TimeSpO2lgte90, 
pctSpO2lgte90,
TimeSpO2lgte80lt90, 
pctSpO2lgte80lt90,
TimeSpO2lgte70lt80, 
pctSpO2lgte70lt80,
TimeSpO2lgte60lt70, 
pctSpO2lgte60lt70
--

from
(select 
	Max([PulseValue]) PulseHighest, 
	Min([PulseValue]) PulseLowest, 
	cast(AVG([PulseValue]) as decimal(10,1)) PulseMean, 
	cast(STDEV([PulseValue]) as decimal(10,1)) PulseSD,
	 @PulseRateMedian as PulseMedian,
	 @ValidPulseRecordingTime as PulseValidTime
from #PulseRateFullTable
--where DeviceMonitoringSessionID in  (Select DeviceMonitoringSessionID from @TmpDmsTbl)
--WHERE  RefTime >= @StartDateTime
--AND RefTime <= @EndDateTime
WHERE ([PulseValue] is NOT NULL and IsGap = 0)) PulseTotals

cross join
(select dbo.getFormattedDurationStringFromSeconds(TimePulse) TimePulseGreater200,
	 isnull(((Cast(TimePulse as float)/ Cast(@ValidPulseTimeInSeconds as float))*100 ),0) pctPulseGreater200
	from (
	select SUM(AdjustedDuration) / 1000  TimePulse
	from #PulseRateFullTable
	where PulseValue > 200
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimePulseGreater200


cross join
(select dbo.getFormattedDurationStringFromSeconds(TimePulse) TimePulseBetween175_200,
	 isnull(((Cast(TimePulse as float)/ Cast(@ValidPulseTimeInSeconds as float))*100 ),0) pctPulseBetween175_200
	from (
	select SUM(AdjustedDuration) / 1000  TimePulse
	from #PulseRateFullTable
	where PulseValue >= 175 and PulseValue <= 200
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimePulseBetween175_200


cross join
(select dbo.getFormattedDurationStringFromSeconds(TimePulse) TimePulseBetween150_174, 
	 isnull(((Cast(TimePulse as float)/ Cast(@ValidPulseTimeInSeconds as float))*100 ),0) pctPulseBetween150_174
	from (
	select SUM(AdjustedDuration) / 1000  TimePulse
	from #PulseRateFullTable
	where PulseValue >= 150 and PulseValue <= 174
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimePulseBetween150_174

cross join
(select dbo.getFormattedDurationStringFromSeconds(TimePulse) TimePulseBetween125_149, 
	 isnull(((Cast(TimePulse as float)/ Cast(@ValidPulseTimeInSeconds as float))*100 ),0) pctPulseBetween125_149
	from (
	select SUM(AdjustedDuration) / 1000  TimePulse
	from #PulseRateFullTable
	where PulseValue >= 125 and PulseValue <= 149
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimePulseBetween125_149


cross join
(select dbo.getFormattedDurationStringFromSeconds(TimePulse) TimePulseBetween100_124,  
	 isnull(((Cast(TimePulse as float)/ Cast(@ValidPulseTimeInSeconds as float))*100 ),0) pctPulseBetween100_124
	from (
	select SUM(AdjustedDuration) / 1000  TimePulse
	from #PulseRateFullTable
	where PulseValue >= 100 and PulseValue <= 124
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimePulseBetween100_124

cross join
(select dbo.getFormattedDurationStringFromSeconds(TimePulse) TimePulseBetween75_99, 
	 isnull(((Cast(TimePulse as float)/ Cast(@ValidPulseTimeInSeconds as float))*100 ),0) pctPulseBetween75_99
	from (
	select SUM(AdjustedDuration) / 1000  TimePulse
	from #PulseRateFullTable
	where PulseValue >= 75 and PulseValue <= 99
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimePulseBetween75_99


cross join
(select dbo.getFormattedDurationStringFromSeconds(TimePulse) TimePulseBetween50_74, 
	 isnull(((Cast(TimePulse as float)/ Cast(@ValidPulseTimeInSeconds as float))*100 ),0) pctPulseBetween50_74
	from (
	select SUM(AdjustedDuration) / 1000  TimePulse
	from #PulseRateFullTable
	where PulseValue >= 50 and PulseValue <= 74
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimePulseBetween50_74

cross join
(select dbo.getFormattedDurationStringFromSeconds(TimePulse) TimePulseBetween40_49,
	 isnull(((Cast(TimePulse as float)/ Cast(@ValidPulseTimeInSeconds as float))*100 ),0) pctPulseBetween40_49
	from (
	select SUM(AdjustedDuration) / 1000  TimePulse
	from #PulseRateFullTable
	where PulseValue >= 40 and PulseValue <= 49
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimePulseBetween40_49

cross join
(select dbo.getFormattedDurationStringFromSeconds(TimePulse) TimePulseBetween20_39, 
	 isnull(((Cast(TimePulse as float)/ Cast(@ValidPulseTimeInSeconds as float))*100 ),0) pctPulseBetween20_39
	from (
	select SUM(AdjustedDuration) / 1000  TimePulse
	from #PulseRateFullTable
	where PulseValue >= 200 and PulseValue <= 39
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimePulseBetween20_39

cross join
(select dbo.getFormattedDurationStringFromSeconds(TimePulse) TimePulseLess20, 
	 isnull(((Cast(TimePulse as float)/ Cast(@ValidPulseTimeInSeconds as float))*100 ),0) pctPulseLess20
	from (
	select SUM(AdjustedDuration) / 1000  TimePulse
	from #PulseRateFullTable
	where PulseValue < 20
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimePulseLess20




-- EtCO2
cross join 
(select 
	Max(EtCO2Value) EtCO2Highest,
	Min(EtCO2Value) EtCO2Lowest,
	cast(Avg(EtCO2Value) as decimal(10,1))  EtCO2Mean,
	cast(STDEV(EtCO2Value) as decimal(10,1))  EtCO2SD,
	@EtCO2Median as EtCO2Median,
	@ValidEtCO2RecordingTime as EtCO2ValidTime
	--MAX(InCO2Value) as InCO2Highest,
	--cast(Avg(INCO2Value) as decimal(10,1))  InCO2Mean
from #EtCO2FullTable
WHERE (EtCO2Value is NOT NULL and IsGap = 0))  EtCO2Totals
--where DeviceMonitoringSessionID in  (Select DeviceMonitoringSessionID from @TmpDmsTbl)
--WHERE  RefTime >= @StartDateTime
--and RefTime <= @EndDateTime) EtCO2Totals


cross join
(Select MAX(InCO2Value) as InCO2Highest,
	cast(Avg(INCO2Value) as decimal(10,1))  InCO2Mean,
	@ValidInCO2RecordingTime as INCO2ValidTime
from #INCO2FullTable
WHERE (INCO2Value is NOT NULL and IsGap = 0))  INCO2Totals

cross join 

(select dbo.getFormattedDurationStringFromSeconds(TimeEtCO2) TimeETCO2Greater70,
	 isnull(((Cast(TimeEtCO2 as float)/ Cast(@ValidEtCO2TimeInSeconds as float))*100 ),0) pctETCO2Greater70
	from (
	select SUM(AdjustedDuration) / 1000  TimeEtCO2
	from #EtCO2FullTable
	where EtCO2Value > 70
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeETCO2Greater70

cross join 

(select dbo.getFormattedDurationStringFromSeconds(TimeEtCO2) TimeETCO2Between61_70,
	 isnull(((Cast(TimeEtCO2 as float)/ Cast(@ValidEtCO2TimeInSeconds as float))*100 ),0) pctETCO2Between61_70
	from (
	select SUM(AdjustedDuration) / 1000  TimeEtCO2
	from #EtCO2FullTable
	where EtCO2Value >= 61 and EtCO2Value <=  70
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeETCO2Between61_70

cross join 

(select dbo.getFormattedDurationStringFromSeconds(TimeEtCO2) TimeETCO2Between51_60,
	 isnull(((Cast(TimeEtCO2 as float)/ Cast(@ValidEtCO2TimeInSeconds as float))*100 ),0) pctETCO2Between51_60
	from (
	select SUM(AdjustedDuration) / 1000  TimeEtCO2
	from #EtCO2FullTable
	where EtCO2Value >= 51 and EtCO2Value <=  60
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeETCO2Between51_60

cross join 

(select dbo.getFormattedDurationStringFromSeconds(TimeEtCO2) TimeETCO2Between46_50,
	 isnull(((Cast(TimeEtCO2 as float)/ Cast(@ValidEtCO2TimeInSeconds as float))*100 ),0) pctETCO2Between46_50
	from (
	select SUM(AdjustedDuration) / 1000  TimeEtCO2
	from #EtCO2FullTable
	where EtCO2Value >= 46 and EtCO2Value <=  50
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeETCO2Between46_50

cross join 

(select dbo.getFormattedDurationStringFromSeconds(TimeEtCO2) TimeETCO2Between41_45,
	 isnull(((Cast(TimeEtCO2 as float)/ Cast(@ValidEtCO2TimeInSeconds as float))*100 ),0) pctETCO2Between41_45
	from (
	select SUM(AdjustedDuration) / 1000  TimeEtCO2
	from #EtCO2FullTable
	where EtCO2Value >= 41 and EtCO2Value <=  45
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeETCO2Between41_45


cross join 

(select dbo.getFormattedDurationStringFromSeconds(TimeEtCO2) TimeETCO2Between36_40,
	 isnull(((Cast(TimeEtCO2 as float)/ Cast(@ValidEtCO2TimeInSeconds as float))*100 ),0) pctETCO2Between36_40
	from (
	select SUM(AdjustedDuration) / 1000  TimeEtCO2
	from #EtCO2FullTable
	where EtCO2Value >= 36 and EtCO2Value <=  40
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeETCO2Between36_40


cross join 

(select dbo.getFormattedDurationStringFromSeconds(TimeEtCO2) TimeETCO2Between30_35,
	 isnull(((Cast(TimeEtCO2 as float)/ Cast(@ValidEtCO2TimeInSeconds as float))*100 ),0) pctETCO2Between30_35
	from (
	select SUM(AdjustedDuration) / 1000  TimeEtCO2
	from #EtCO2FullTable
	where EtCO2Value >= 30 and EtCO2Value <=  35
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeETCO2Between30_35

cross join 

(select dbo.getFormattedDurationStringFromSeconds(TimeEtCO2) TimeETCO2Between20_29,
	 isnull(((Cast(TimeEtCO2 as float)/ Cast(@ValidEtCO2TimeInSeconds as float))*100 ),0) pctETCO2Between20_29
	from (
	select SUM(AdjustedDuration) / 1000  TimeEtCO2
	from #EtCO2FullTable
	where EtCO2Value >=20 and EtCO2Value <=  29
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeETCO2Between20_29

cross join 

(select dbo.getFormattedDurationStringFromSeconds(TimeEtCO2) TimeETCO2Between10_19,
	 isnull(((Cast(TimeEtCO2 as float)/ Cast(@ValidEtCO2TimeInSeconds as float))*100 ),0) pctETCO2Between10_19
	from (
	select SUM(AdjustedDuration) / 1000  TimeEtCO2
	from #EtCO2FullTable
	where EtCO2Value >= 10 and EtCO2Value <=  19
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeETCO2Between10_19

cross join 

(select dbo.getFormattedDurationStringFromSeconds(TimeEtCO2) TimeETCO2Less10, 
	 isnull(((Cast(TimeEtCO2 as float)/ Cast(@ValidEtCO2TimeInSeconds as float))*100 ),0) pctETCO2Less10
	from (
	select SUM(AdjustedDuration) / 1000  TimeEtCO2
	from #EtCO2FullTable
	where EtCO2Value <  10
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeETCO2Less10



cross join 
(select 
	Max(SpO2Value) SpO2Highest,
	Min(SpO2Value) SpO2Lowest,
	cast(Avg(SpO2Value) as decimal(10,1))  SpO2Mean,
	cast(STDEV(SpO2Value) as decimal(10,1))  SpO2SD,
	@SPO2Median as SPO2Median,
	@ValidSPO2RecordingTime as SPO2ValidTime
from #SPO2FullTable
WHERE (SpO2Value is NOT NULL and IsGap = 0))  SpO2Totals


cross join 
(select 
	Max(RespRateValue) RespRateHighest ,
	Min(RespRateValue) RespRateLowest ,
	cast(Avg(RespRateValue) as decimal(10,1))  RespRateMean  ,
	cast(STDEV(RespRateValue) as decimal(10,1))  RespRateSD ,
	@RespRateMedian as RespRateMedian ,
	@ValidRespRateRecordingTime as RespRateValidTime

from #RespRateFullTable
WHERE (RespRateValue is NOT NULL and IsGap = 0))  RespRateTotals

cross join
(select dbo.getFormattedDurationStringFromSeconds(TimeRespRate) TimeRespRateGreater70,
	 isnull(((Cast(TimeRespRate as float)/ Cast(@ValidRespRateTimeInSeconds as float))*100 ),0) pctRespRateGreater70
	from (
	select SUM(AdjustedDuration) / 1000  TimeRespRate
	from #RespRateFullTable
	where RespRateValue > 70
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeRespRateGreater70

cross join
(select dbo.getFormattedDurationStringFromSeconds(TimeRespRate) TimeRespRateBetween61_70, 
	 isnull(((Cast(TimeRespRate as float)/ Cast(@ValidRespRateTimeInSeconds as float))*100 ),0) pctRespRateBetween61_70
	from (
	select SUM(AdjustedDuration) / 1000  TimeRespRate
	from #RespRateFullTable
	where RespRateValue >= 61 and RespRateValue <= 70
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeRespRateBetween61_70

cross join
(select dbo.getFormattedDurationStringFromSeconds(TimeRespRate) TimeRespRateBetween51_60,
	 isnull(((Cast(TimeRespRate as float)/ Cast(@ValidRespRateTimeInSeconds as float))*100 ),0) pctRespRateBetween51_60
	from (
	select SUM(AdjustedDuration) / 1000  TimeRespRate
	from #RespRateFullTable
	where RespRateValue >= 51 and RespRateValue <= 60
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeRespRateBetween51_60

cross join
(select dbo.getFormattedDurationStringFromSeconds(TimeRespRate) TimeRespRateBetween41_50,
	 isnull(((Cast(TimeRespRate as float)/ Cast(@ValidRespRateTimeInSeconds as float))*100 ),0) pctRespRateBetween41_50
	from (
	select SUM(AdjustedDuration) / 1000  TimeRespRate
	from #RespRateFullTable
	where RespRateValue >= 41 and RespRateValue <= 50
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeRespRateBetween41_50

cross join
(select dbo.getFormattedDurationStringFromSeconds(TimeRespRate) TimeRespRateBetween31_40,
	 isnull(((Cast(TimeRespRate as float)/ Cast(@ValidRespRateTimeInSeconds as float))*100 ),0) pctRespRateBetween31_40
	from (
	select SUM(AdjustedDuration) / 1000  TimeRespRate
	from #RespRateFullTable
	where RespRateValue >= 31 and RespRateValue <= 40
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeRespRateBetween31_40

cross join
(select dbo.getFormattedDurationStringFromSeconds(TimeRespRate) TimeRespRateBetween21_30,
	 isnull(((Cast(TimeRespRate as float)/ Cast(@ValidRespRateTimeInSeconds as float))*100 ),0) pctRespRateBetween21_30
	from (
	select SUM(AdjustedDuration) / 1000  TimeRespRate
	from #RespRateFullTable
	where RespRateValue >= 21 and RespRateValue <= 30
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeRespRateBetween21_30

cross join
(select dbo.getFormattedDurationStringFromSeconds(TimeRespRate) TimeRespRateBetween16_20,
	 isnull(((Cast(TimeRespRate as float)/ Cast(@ValidRespRateTimeInSeconds as float))*100 ),0) pctRespRateBetween16_20
	from (
	select SUM(AdjustedDuration) / 1000  TimeRespRate
	from #RespRateFullTable
	where RespRateValue >= 16 and RespRateValue <= 20
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeRespRateBetween16_20

cross join
(select dbo.getFormattedDurationStringFromSeconds(TimeRespRate) TimeRespRateBetween11_15,
	 isnull(((Cast(TimeRespRate as float)/ Cast(@ValidRespRateTimeInSeconds as float))*100 ),0) pctRespRateBetween11_15
	from (
	select SUM(AdjustedDuration) / 1000  TimeRespRate
	from #RespRateFullTable
	where RespRateValue >= 11 and RespRateValue <= 15
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeRespRateBetween11_15

cross join
(select dbo.getFormattedDurationStringFromSeconds(TimeRespRate) TimeRespRateBetween6_10,
	 isnull(((Cast(TimeRespRate as float)/ Cast(@ValidRespRateTimeInSeconds as float))*100 ),0) pctRespRateBetween6_10
	from (
	select SUM(AdjustedDuration) / 1000  TimeRespRate
	from #RespRateFullTable
	where RespRateValue >= 6 and RespRateValue <= 10
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeRespRateBetween6_10

cross join
(select dbo.getFormattedDurationStringFromSeconds(TimeRespRate) TimeRespRateLess6, 
	 isnull(((Cast(TimeRespRate as float)/ Cast(@ValidRespRateTimeInSeconds as float))*100 ),0) pctRespRateLess6
	from (
	select SUM(AdjustedDuration) / 1000  TimeRespRate
	from #RespRateFullTable
	where RespRateValue < 6
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeRespRateLess6

------------------------------------------------------------------------------
--
------------------------------------------------------------------------------

--TimeSpO2gt98,
--pctSpO2gt98,

cross join
(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2gt98, 
	 isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2gt98
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value > 98
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2gt98

--TimeSpO2equal98 ,
--pctSpO2equal98 ,

cross join

(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2equal98, 
	 isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2equal98
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value = 98
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2equal98

cross join

(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2equal97, 
	 isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2equal97
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value = 97
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2equal97


cross join

(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2equal96, 
	 isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2equal96
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value = 96
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2equal96


cross join

(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2equal95, 
	 isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2equal95
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value = 95
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2equal95


cross join

(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2equal94, 
	 isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2equal94
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value = 94
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2equal94


cross join

(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2equal93, 
	 isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2equal93
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value = 93
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2equal93


cross join

(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2equal92, 
	 isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2equal92
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value = 92
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2equal92


cross join

(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2equal91, 
	 isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2equal91
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value = 91
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2equal91


cross join

(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2equal90, 
	 isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2equal90
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value = 90
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2equal90

-- start the 80s

cross join

(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2equal89, 
	 isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2equal89
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value = 89
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2equal89

cross join

(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2equal88, 
	 isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2equal88
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value = 88
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2equal88

cross join

(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2equal87, 
	 isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2equal87
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value = 87
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2equal87


cross join

(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2equal86, 
	 isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2equal86
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value = 86
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2equal86


cross join

(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2equal85, 
	 isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2equal85
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value = 85
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2equal85


cross join

(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2equal84, 
	 isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2equal84
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value = 84
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2equal84


cross join

(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2equal83, 
	 isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2equal83
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value = 83
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2equal83


cross join

(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2equal82, 
	 isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2equal82
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value = 82
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2equal82


cross join

(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2equal81, 
	 isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2equal81
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value = 81
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2equal81


cross join

(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2equal80, 
	 isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2equal80
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value = 80
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2equal80


-- start the 70s


cross join

(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2equal79, 
	 isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2equal79
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value = 79
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2equal79

cross join

(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2equal78, 
	 isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2equal78
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value = 78
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2equal78

cross join

(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2equal77, 
	 isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2equal77
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value = 77
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2equal77


cross join

(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2equal76, 
	 isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2equal76
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value = 76
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2equal76


cross join

(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2equal75, 
	 isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2equal75
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value = 75
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2equal75


cross join

(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2equal74, 
	 isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2equal74
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value = 74
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2equal74


cross join

(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2equal73, 
	 isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2equal73
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value = 73
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2equal73


cross join

(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2equal72, 
	 isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2equal72
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value = 72
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2equal72


cross join

(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2equal71, 
	 isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2equal71
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value = 71
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2equal71


cross join

(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2equal70, 
	 isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2equal70
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value = 70
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2equal70

------------------------------------------------

cross join
(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2lt90, 
	 isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2lt90
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value < 90
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2lt90
cross join
(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2lt80, 
isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2lt80
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value < 80
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2lt80
cross join
(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2lt70, 
isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0)  pctSpO2lt70
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable 
	where SpO2Value < 70
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2lt70
cross join
(select dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2lt60, 
isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0)  pctSpO2lt60
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value < 60
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2lt60
cross join
(select  dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2lt89, 
isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2lt89,
CASE WHEN TimeSpO2 = 0 THEN 'There was no time spent with a saturation less than 89' else 'Time spent with saturation less than 89:  ' + dbo.getFormattedDurationStringFromSeconds(TimeSpO2) end as TimeLessThan89
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value < 88
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2lt89
cross join
(select 
dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2lgte90, 
isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2lgte90
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable 
	where SpO2Value >= 90
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2lgte90
cross join
(select 
dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2lgte80lt90, 
isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2lgte80lt90
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable 
	where SpO2Value >= 80
	and SpO2Value < 90
	and (IsGap = 0 and ExcludedTime = 0)) v
) TimeSpO2lgte80lt90
cross join
(select 
dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2lgte70lt80, 
isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2lgte70lt80
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable
	where SpO2Value >= 70
	and SpO2Value < 80
	and (IsGap = 0 and ExcludedTime = 0)) v)
TimeSpO2lgte70lt80
cross join
(select 
dbo.getFormattedDurationStringFromSeconds(TimeSpO2) TimeSpO2lgte60lt70, 
isnull(((Cast(TimeSpO2 as float)/ Cast(@ValidTimeInSeconds as float))*100 ),0) pctSpO2lgte60lt70
	from (
	select SUM(AdjustedDuration) / 1000  TimeSpO2
	from #SPO2FullTable 
	where SpO2Value >= 60
	and SpO2Value < 70
	and (IsGap = 0 and ExcludedTime = 0)) v
)  TimeSpO2lgte60lt70

select 
RecordingSeconds as RecordingSeconds,
TotalTimeRecording as TotalTimeRecording,
PatientID as PatientID,
PatientName,
--DoctorName,
TimeExcludedSampling as TimeExcludedSampling,

PulseHighest, 
PulseLowest, 
PulseMean, 
PulseSD,
PulseMedian,
PulseValidTime,
TimePulseGreater200, 
pctPulseGreater200,

TimePulseBetween175_200, 
pctPulseBetween175_200, 

TimePulseBetween150_174, 
pctPulseBetween150_174, 

TimePulseBetween125_149, 
pctPulseBetween125_149,

TimePulseBetween100_124, 
pctPulseBetween100_124,

TimePulseBetween75_99, 
pctPulseBetween75_99,

TimePulseBetween50_74, 
pctPulseBetween50_74,

TimePulseBetween40_49, 
pctPulseBetween40_49,

TimePulseBetween20_39, 
pctPulseBetween20_39,

TimePulseLess20, 
pctPulseLess20,

--EtCO2 section

EtCO2Highest,
EtCO2Lowest, 
EtCO2Mean, 
EtCO2SD, 
EtCO2Median, 
EtCO2ValidTime, 
InCO2Highest,
InCO2Mean,
InCO2ValidTime,


TimeETCO2Greater70, 
pctETCO2Greater70,

TimeETCO2Between61_70, 
pctETCO2Between61_70, 

TimeETCO2Between51_60, 
pctETCO2Between51_60, 

TimeETCO2Between46_50, 
pctETCO2Between46_50, 

TimeETCO2Between41_45, 
pctETCO2Between41_45, 

TimeETCO2Between36_40, 
pctETCO2Between36_40, 

TimeETCO2Between30_35, 
pctETCO2Between30_35, 

TimeETCO2Between20_29, 
pctETCO2Between20_29, 

TimeETCO2Between10_19, 
pctETCO2Between10_19, 

TimeETCO2Less10, 
pctETCO2Less10, 


--End EtCO2 Section
SpO2Highest,
SpO2Lowest,
SpO2Mean,
SpO2Median,
SpO2SD,
SPO2ValidTime,
--

RespRateHighest ,
RespRateLowest ,
RespRateMean ,
RespRateMedian ,
RespRateSD ,
RespRateValidTime,


TimeRespRateGreater70, 
pctRespRateGreater70,

TimeRespRateBetween61_70, 
pctRespRateBetween61_70, 

TimeRespRateBetween51_60, 
pctRespRateBetween51_60, 

TimeRespRateBetween41_50, 
pctRespRateBetween41_50, 

TimeRespRateBetween31_40, 
pctRespRateBetween31_40, 

TimeRespRateBetween21_30, 
pctRespRateBetween21_30, 

TimeRespRateBetween16_20, 
pctRespRateBetween16_20, 

TimeRespRateBetween11_15, 
pctRespRateBetween11_15, 

TimeRespRateBetween6_10, 
pctRespRateBetween6_10, 

TimeRespRateLess6, 
pctRespRateLess6, 

TimeSpO2gt98,
pctSpO2gt98,

TimeSpO2equal98 ,
pctSpO2equal98 ,

TimeSpO2equal97 ,
pctSpO2equal97 ,

TimeSpO2equal96 ,
pctSpO2equal96 ,

TimeSpO2equal95,
pctSpO2equal95 ,

TimeSpO2equal94 ,
pctSpO2equal94 ,

TimeSpO2equal93 ,
pctSpO2equal93 ,

TimeSpO2equal92 ,
pctSpO2equal92 ,

TimeSpO2equal91 ,
pctSpO2equal91 ,

TimeSpO2equal90 ,
pctSpO2equal90 ,

TimeSpO2equal89 ,
pctSpO2equal89 ,

TimeSpO2equal88 ,
pctSpO2equal88 ,

TimeSpO2equal87 ,
pctSpO2equal87 ,

TimeSpO2equal86 ,
pctSpO2equal86 ,

TimeSpO2equal85 ,
pctSpO2equal85 ,

TimeSpO2equal84 ,
pctSpO2equal84 ,

TimeSpO2equal83 ,
pctSpO2equal83 ,

TimeSpO2equal82 ,
pctSpO2equal82 ,

TimeSpO2equal81 ,
pctSpO2equal81 ,

TimeSpO2equal80 ,
pctSpO2equal80 ,

TimeSpO2equal79,
pctSpO2equal79 ,

TimeSpO2equal78 ,
pctSpO2equal78,

TimeSpO2equal77 ,
pctSpO2equal77 ,

TimeSpO2equal76 ,
pctSpO2equal76 ,

TimeSpO2equal75 ,
pctSpO2equal75 ,

TimeSpO2equal74 ,
pctSpO2equal74 ,

TimeSpO2equal73 ,
pctSpO2equal73 ,

TimeSpO2equal72 ,
pctSpO2equal72 ,

TimeSpO2equal71 ,
pctSpO2equal71 ,

TimeSpO2equal70 ,
pctSpO2equal70 ,


TimeSpO2lt90, 
pctSpO2lt90,
TimeSpO2lt80, 
pctSpO2lt80,
TimeSpO2lt70, 
pctSpO2lt70,
TimeSpO2lt60, 
pctSpO2lt60,
TimeSpO2lt89, 
pctSpO2lt89,
TimeLessThan89,
TimeSpO2lgte90, 
pctSpO2lgte90,
TimeSpO2lgte80lt90, 
pctSpO2lgte80lt90,
TimeSpO2lgte70lt80, 
pctSpO2lgte70lt80,
TimeSpO2lgte60lt70, 
pctSpO2lgte60lt70

from @results;



-- DROP ALL TEMP TABLES HERE

-- ALL SPO2 TEMP TABLES ------------------
IF OBJECT_ID('tempdb..#SpO2') IS NOT NULL
   DROP TABLE #SpO2;

   IF OBJECT_ID('tempdb..#SPO2FullTable') IS NOT NULL
   DROP TABLE #SPO2FullTable;
------------------------------------------

-- ALL RESPIRATION RATE TEMP TABLES ------

IF OBJECT_ID('tempdb..#RespRate') IS NOT NULL
   DROP TABLE #RespRateFullTable;

IF OBJECT_ID('tempdb..#RespRateFullTable') IS NOT NULL
   DROP TABLE #RespRateFullTable;

-------------------------------------------

-- ALL ETCO2 Temp Tables -------------------

IF OBJECT_ID('tempdb..#EtCO2') IS NOT NULL
   DROP TABLE #EtCO2;

IF OBJECT_ID('tempdb..#EtCO2FullTable') IS NOT NULL
   DROP TABLE #EtCO2FullTable;

--------------------------------------------

-- ALL InCO2 Temp Tables -------------------

IF OBJECT_ID('tempdb..#InCO2') IS NOT NULL
   DROP TABLE #InCO2;

IF OBJECT_ID('tempdb..#InCO2FullTable') IS NOT NULL
   DROP TABLE #InCO2FullTable;

--------------------------------------------

-- ALL Pulse Temp Tables -------------------

IF OBJECT_ID('tempdb..#PulseRate') IS NOT NULL
   DROP TABLE #PulseRate;

IF OBJECT_ID('tempdb..#PulseRateFullTable') IS NOT NULL
   DROP TABLE #PulseRateFullTable;

--------------------------------------------

end;

