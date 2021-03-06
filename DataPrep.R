#################
### LOAD DATA ###
#################

#Demographic data (n=1629)
data.demo <- read.csv("/data/joy/BBL/studies/pnc/n1601_dataFreeze/demographics/n1601_demographics_go1_20161212.csv", header=TRUE, na.strings="NA")

#Psychopathology bifactors from Tyler's bifactor analysis (n=1601)
data.bifactors <- read.csv("/data/joy/BBL/studies/pnc/n1601_dataFreeze/clinical/n1601_goassess_itemwise_bifactor_scores_20161219.csv", header=TRUE, na.strings="NA")

##Exclusion criteria
#Health exclusion (use the healthExcludev2 variable) (n=1601; no missing data)
data.healthExclude <- read.csv("/data/joy/BBL/studies/pnc/n1601_dataFreeze/health/n1601_health_20170421.csv", header=TRUE)

#T1 QA exclusion (n=1601)
data.t1QA <- read.csv("/data/joy/BBL/studies/pnc/n1601_dataFreeze/neuroimaging/t1struct/n1601_t1QaData_20170306.csv", header=TRUE, na.strings="NA")

##################
#### DATA PREP ###
##################

#Transform the age variable from months to years
data.demo$age <- (data.demo$ageAtScan1)/12

#Recode male as 0 and female as 1 (0=male, 1=female)
#males
data.demo$sex[which(data.demo$sex==1)] <- 0
#females
data.demo$sex[which(data.demo$sex==2)] <- 1

#Make sex a factor
data.demo$sex <- as.factor(data.demo$sex)

#Define white vs nonwhite
data.demo$white <- 0
data.demo$white[which(data.demo$race==1)] <- 1

#Make white a factor
data.demo$white <- as.factor(data.demo$white)

##################
### MERGE DATA ###
##################
dataMerge1 <-merge(data.demo,data.bifactors, by=c("bblid","scanid"), all=TRUE)
dataMerge2 <-merge(dataMerge1,data.healthExclude, by=c("bblid","scanid"), all=TRUE)
dataMerge3 <-merge(dataMerge2,data.t1QA, by=c("bblid","scanid"), all=TRUE)

#Retain only the 1601 bblids (demographics has 1629)
data.n1601 <- dataMerge3[match(data.t1QA$bblid, dataMerge3$bblid, nomatch=0),]

#Put bblids in ascending order
data.ordered <- data.n1601[order(data.n1601$bblid),]

#Count the number of subjects (should be 1601)
n <- nrow(data.ordered)

########################
### APPLY EXCLUSIONS ### 
########################
##Count the total number excluded for healthExcludev2=1 (1=Excludes those with medical rating 3/4, major incidental findings that distort anatomy, psychoactive medical medications)
#Included: n=1447; Excluded: n=154, but medical.exclude (n=81) + incidental.exclude (n=20) + medicalMed.exclude (n=64) = 165, so 11 people were excluded on the basis of two or more of these criteria
data.final <- data.ordered
data.final$ACROSS.INCLUDE.health <- 1
data.final$ACROSS.INCLUDE.health[data.final$healthExcludev2==1] <- 0
health.include<-sum(data.final$ACROSS.INCLUDE.health)
health.exclude<-1601-health.include

#Count the number excluded just medical rating 3/4 (GOAssess Medial History and CHOP EMR were used to define one summary rating for overall medical problems) (n=81)
data.final$ACROSS.INCLUDE.medical <- 1
data.final$ACROSS.INCLUDE.medical[data.final$medicalratingExclude==1] <- 0
medical.include<-sum(data.final$ACROSS.INCLUDE.medical)
medical.exclude<-1601-medical.include

#Count the number excluded for just major incidental findings that distort anatomy (n=20)
data.final$ACROSS.INCLUDE.incidental <- 1
data.final$ACROSS.INCLUDE.incidental[data.final$incidentalFindingExclude==1] <- 0
incidental.include<-sum(data.final$ACROSS.INCLUDE.incidental)
incidental.exclude<-1601-incidental.include

#Count the number excluded for just psychoactive medical medications (n=64)
data.final$ACROSS.INCLUDE.medicalMed <- 1
data.final$ACROSS.INCLUDE.medicalMed[data.final$psychoactiveMedMedicalv2==1] <- 0
medicalMed.include<-sum(data.final$ACROSS.INCLUDE.medicalMed)
medicalMed.exclude<-1601-medicalMed.include

#Subset the data to just the  that pass healthExcludev2 (n=1447)
data.subset <-data.final[which(data.final$ACROSS.INCLUDE.health == 1), ]

##Count the number excluded for failing to meet structural image quality assurance protocols
#Included: n=1396; Excluded: n=51
data.subset$ACROSS.INCLUDE.QA <- 1
data.subset$ACROSS.INCLUDE.QA[data.subset$t1Exclude==1] <- 0
QA.include<-sum(data.subset$ACROSS.INCLUDE.QA)
QA.exclude<-1447-QA.include

###Exclude those with ALL problems (health problems and problems with their t1 data) (included n=1396)
data.exclude <- data.subset[which(data.subset$healthExcludev2==0 & data.subset$t1Exclude == 0 ),]

##########################
### BASIC DEMOGRAPHICS ###
##########################

meanAge <- mean(data.exclude$age)
sdAge <- sd(data.exclude$age)
rangeAge <- range(data.exclude$age)
genderTable <- table(data.exclude$sex)
raceTable <- table(data.exclude$white)

##########################
### SAVE FINAL DATASET ###
##########################

#n=1396
saveRDS(data.exclude,"/data/jux/BBL/projects/pncNmf/subjectData/n1396_T1_subjData.rds")

#Save the bblids and scanids for the final sample
IDs <- c("bblid", "scanid")
bblidsScanids <- data.exclude[IDs]

#Remove header
names(bblidsScanids) <- NULL

#Save list
write.csv(bblidsScanids, file="/data/jux/BBL/projects/pncNmf/subjectData/n1396_T1_bblids_scanids.csv", row.names=FALSE)

