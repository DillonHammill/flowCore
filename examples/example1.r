#library(rflowcyt)
library(graph)
#library(prada)
library(geneplotter)
## FOR DEVELOPMENT PURPOSES ONLY
#library(flowcore)
source("R/AllClasses.R")
source("R/AllGeneric.R")
source("R/fcsFrame-methods.R")
source("R/filter-functions.R")
source("R/filter-methods.R")
source("R/filterResult-accessors.R")
source("R/readFCS-functions.R")
source("R/transformation-functions.R")
source("R/transformation-methods.R")

## create the data to be used
## these are three interesting wells from a BD FACS CAP(TM) plate
## with PBMS (perpheral blood monocytes) on the plate
b08 = readFCS("data/0877408774.B08",transformation=TRUE)
e07 = readFCS("data/0877408774.E07",transformation=TRUE)
f06 = readFCS("data/0877408774.F06",transformation=TRUE)
class(b08)
#[1] "fcsFrame"
dim(b08@exprs)
#[1] 10000     8
dimnames(b08@exprs)[[2]]
#  $P1N    $P2N    $P3N    $P4N    $P5N    $P6N    $P7N    $P8N 
#"FSC-H" "SSC-H" "FL1-H" "FL2-H" "FL3-H" "FL1-A" "FL4-H"  "Time" 

## transform the fluorescence readings to the  log scale
range(b08@exprs[,"FL1-H"])
#[1]    1.000 3681.141
logTransform = new("logTransformation",transformationId="log10",
	parameters=c("FL1-H","FL2-H","FL3-H"),
	r=1,d=1,logbase=10)
b08 = applyTransformation(logTransform,b08)
#[1] "Logarithmical transformation applied on flowset (file:b08) a fcsFrame object"
range(b08@exprs[,"FL1-H"])
#[1]    1.000 3681.141
range(b08@exprs[,"FL2-H"])
#[1] 0 4

e07 = applyTransformation(logTransform,e07)
f06 = applyTransformation(logTransform,f06)

## these are the transformed values
plot(b08,plotParameters=c("FSC-H","SSC-H"),main="B08")
plot(b08,plotParameters=c("FL1-H","FL2-H"),main="B08")
plot(b08,plotParameters=c("FSC-H","SSC-H"),main="B08")
plot(e07,plotParameters=c("FSC-H","SSC-H",main="E07"))
plot(f06,plotParameters=c("FSC-H","SSC-H"),main="F06")


## the first gate is a rectangleGate to filter out debris
min1=c(200,0)
max1=c(800,800)
filter1 = new("rectangleGate",filterId="Nondebris",parameters=c("FSC-H","SSC-H"),
  min=min1,max=max1)
b08.result1 = applyFilter(filter1,b08)
plot(b08,y=b08.result1)
sum(b08.result1@subSet)
#[1] 8234
##
e07.result1 = applyFilter(filter1,e07)
plot(e07,y=e07.result1)
sum(e07.result1@subSet)
#[1] 8421
##
f06.result1 = applyFilter(filter1,f06)
plot(f06,y=f06.result1)
sum(f06.result1@subSet)
#[1] 8738


## the second gate gets the live cells
filter2 = new("norm2Filter",filterId="Live Cells",scale.factor=2,method="covMcd",parameters=c("FSC-H","SSC-H"))
b08.result2 = applyFilter(filter2,b08,b08.result1)
plot(b08,y=b08.result2,parent=b08.result1,xlim=c(0,1024),ylim=c(0,1024))
sum(b08.result2@subSet)
#[1] 6486
##
e07.result2 = applyFilter(filter2,e07,e07.result1)
plot(e07,y=e07.result2,parent=e07.result1,xlim=c(0,1024),ylim=c(0,1024))
sum(e07.result2@subSet)
#[1] 6390
f06.result2 = applyFilter(filter2,f06,f06.result1)
plot(f06,y=f06.result2,parent=f06.result1,xlim=c(0,1024),ylim=c(0,1024))
sum(f06.result2@subSet)
#[1] 6954

## the third-fifth gates get the positive cells for the marker in FL1-H
## this is a really interesting example because it illustrates that there
## are two subpopulations. Naturally we would like to automatically find them
## In this case we want to now what percent the positive population in FL1-H is of the
## total population
plot(b08,parent=b08.result2,plotParameters=c("FSC-H","FL1-H"),ylim=c(0,1024),xlim=c(0,4))
filter3 = new("rectangleGate",filterId="FL1-H+",parameters="FL1-H",min=1.5,max=Inf)
b08.result3 = applyFilter(filter3,b08,b08.result2)
plot(b08,y=b08.result3,parent=b08.result2,plotParameters=c("FSC-H","FL1-H"),
          xlim=c(0,1024),ylim=c(0,4))
sum(b08.result3@subSet)
#[1] 3560
sum(b08.result3@subSet)/sum(b08.result2@subSet)
#[1] 0.5488745

filter4=new("norm2Filter",filterId="FL1-H+",scale.factor=2,method="covMcd",parameters=c("FSC-H","FL1-H"))
b08.result4 = applyFilter(filter4,b08,b08.result2)
plot(b08,y=b08.result4,parent=b08.result2,plotParameters=c("FSC-H","FL1-H"),
          xlim=c(0,1024),ylim=c(0,4))
sum(b08.result4@subSet)
#[1] 3487

###############################################
## stop here because this filter requires a NOT gate
b08.result5 = applyFilter(filter4,b08,b08.result2@subSet-b08.result4@subSet)
plot(b08,y=b08.result5,parent=b08.result2@subSet,plotParameters=c("FSC-H","FL1-H"),
          xlim=c(0,1024),ylim=c(0,1024))
sum(b08.result5@subSet)
#[1] 2568
sum(b08.result4@subSet)/(sum(b08.result4@subSet)+sum(b08.result5@subSet))
#[1] 0.5758877


## the sixth-eighth gates get the positive cells for the marker in FL2-H
## in this case there is only a negative population
plot(b08,parent=b08.result2@subSet,plotParameters=c("FSC-H","FL2-H"),ylim=c(0,1024),xlim=c(0,1024))
filter6 = new("rectangleGate",filterId="FL2-H+",parameters="FL2-H",min=600,max=Inf)
b08.result6 = applyFilter(filter6,b08,b08.result2@subSet)
plot(b08,y=b08.result6,parent=b08.result2@subSet,plotParameters=c("FSC-H","FL2-H"),
          xlim=c(0,1024),ylim=c(0,1024))
sum(b08.result6@subSet)
#[1] 12
sum(b08.result6@subSet)/sum(b08.result2@subSet)
#[1] 0.001
filter7=new("norm2Filter",filterId="FL2-H-",scale.factor=2,method="covMcd",parameters=c("FSC-H","FL2-H"))
b08.result7 = applyFilter(filter7,b08,b08.result2@subSet)
plot(b08,y=b08.result7,parent=b08.result2@subSet,plotParameters=c("FSC-H","FL2-H"),
          xlim=c(0,1024),ylim=c(0,1024))
sum(b08.result7@subSet)
#[1] 5422

## this doesn't produce a sensible result since there is no positive population remaining
b08.result8 = applyFilter(filter7,b08,b08.result2@subSet-b08.result7@subSet)
plot(b08,y=b08.result8,parent=b08.result2@subSet,plotParameters=c("FSC-H","FL2-H"),
          xlim=c(0,1024),ylim=c(0,1024))
sum(b08.result8@subSet)
#[1] 
sum(b08.result8@subSet8)/(sum(b08.result7@subSet)+sum(b08.result8@subSet))
#[1] 


## the ninth-eleventh gates get the positive cells for the marker in FL3-H
## again, there is only a negativ3e population here
plot(b08,parent=b08.result2@subSet,plotParameters=c("FSC-H","FL3-H"),ylim=c(0,1024),xlim=c(0,1024))
filter9 = new("rectangleGate",filterId="FL3-H+",parameters="FL3-H",min=500,max=Inf)
b08.result9 = applyFilter(filter9,b08,b08.result2@subSet)
plot(b08,y=b08.result9,parent=b08.result2@subSet,plotParameters=c("FSC-H","FL3-H"),
          xlim=c(0,1024),ylim=c(0,1024))
sum(b08.result9@subSet)
#[1] 0
sum(b08.result9@subSet)/sum(b08.result2@subSet)
#[1] 0
filter10=new("norm2Filter",filterId="FL3-H-",scale.factor=2,method="covMcd",parameters=c("FSC-H","FL3-H"))
b08.result10 = applyFilter(filter10,b08,b08.result2@subSet)
plot(b08,y=b08.result10,parent=b08.result2@subSet,plotParameters=c("FSC-H","FL3-H"),
          xlim=c(0,1024),ylim=c(0,1024))
sum(b08.result10@subSet)
#[1] 5834

## this doesn't produce a sensible result since there is no positive population remaining
b08.result11 = applyFilter(filter10,b08,b08.result2@subSet-b08.result10@subSet)
plot(b08,y=b08.result11,parent=b08.result2@subSet,plotParameters=c("FSC-H","FL3-H"),
          xlim=c(0,1024),ylim=c(0,1024))
sum(b08.result11@subSet)
#[1] 
sum(b08.result11@subSet)/(sum(b08.result11@subSet)+sum(b08.result10@subSet))
#[1] 


