# stix-docker
> Dockerfile for Ryan Layer's stix sv annotator + associated tools

### About
This is my first docker image. 

Uploaded to the hub here: https://hub.docker.com/repository/docker/philliparichmond/stix-sv/general 

I had trouble installing giggle + stix (libcurl hatred in shared HPC with make-based install).

Tools in this image:  
- Samtools: [https://github.com/samtools/samtools](https://github.com/samtools/samtools)  
- STIX: [https://github.com/ryanlayer/stix](https://github.com/ryanlayer/stix)  
- excord: [https://github.com/brentp/excord](https://github.com/brentp/excord)  
- giggle: [https://github.com/ryanlayer/giggle](https://github.com/ryanlayer/giggle)  

I made this with motivation and starting point here: https://github.com/apaul7/docker-stix


### Building
Making the image from the command line with docker installed on my mac:
```
docker build -t philliparichmond/stix-sv:20220421 /some/path/to/this/repo/stix-docker/
```

I then added it to docker hub with this: 
```
docker push philliparichmond/stix-sv:20220421
```

### Pulling + usage
You can pull the image from the Public docker repo:
```
docker pull docker://philliparichmond/stix-sv:20220421
```

### Testing + usage  
Testing that it works and some usage pieces:  
Samtools  
```
docker run -i philliparichmond/stix-sv:20220421 samtools
```

Stix
```
docker run -i philliparichmond/stix-sv:20220421 stix
```

Giggle
```
docker run -i philliparichmond/stix-sv:20220421 giggle
```

excord
```
docker run -i philliparichmond/stix-sv:20220421 excord
```


### With Singularity

#### Singularity pull docker image
```
singularity pull  docker://philliparichmond/stix-sv:20220421
```

#### Singularity run docker image 
```
singularity exec -i stix-sv_20220421.sif samtools
```

```
singularity exec -i stix-sv_20220421.sif stix
```

```
singularity exec -i stix-sv_20220421.sif giggle
```

```
singularity exec -i stix-sv_20220421.sif excord
```

## Example usage of these tools with 1kG_Trio data

### Make Giggle Index from Excord Output
I have these files in a directory called ```Excord_Output```
```
Excord_Output/HG00403.bed.gz
Excord_Output/HG00404.bed.gz
...
```
For ~1500 samples.

I create a giggle index like this using a docker for Stix+giggle+excord+samtools, which you can get here: [https://hub.docker.com/repository/docker/philliparichmond/stix-sv/general](https://hub.docker.com/repository/docker/philliparichmond/stix-sv/general)

```
Stix_SIF=/mnt/common/Precision/STIX/stix.sif

WorkingDir=/mnt/common/OPEN_DATA/1kG_Trio/
DataDir=$WorkingDir/Excord_Output/
IndexDir=${WorkingDir}STIX_Index
rm -rf $IndexDir
mkdir -p $IndexDir

# Make a giggle index bash script. This is necessary because singularity won't evaluate the blob format of $IndexDir/*gz
IndexScript=$WorkingDir/IndexGiggle.sh
# clean up if it exists already
rm $IndexScript

# here I'm making this giggle script that will be passed to singularity below
# Have to do this because singularity can't evaluate glob format for *.bed.gz
# Thank Brentp for that help on smoove.

echo cd $DataDir > $IndexScript
echo giggle index -s -f -o "$IndexDir" -i "*.bed.gz" >> $IndexScript

# Run giggle index
singularity exec \
	-B $WorkingDir \
	-B $IndexDir \
	-B $DataDir \
	$GiggleSIF \
	bash $IndexScript 
```

The index command looks like this:
```
giggle index -s -f -o /mnt/common/OPEN_DATA/1kG_Trio/STIX_Index -i /mnt/common/OPEN_DATA/1kG_Trio//Excord_Output/*.bed.gz
```

Now this gives me a nice large directory with a bunch of ```.dat``` and ```.idx``` files. 
Unclear if it's correct, ran for ~5 min and exits with no errors.
```
STIX_Index/
```

### Make PED file with sample name and sample .bed.gz file

Next step is I want to make a PED file containing the sample + filenames. I do that with a little bash script working on the input directory for excord files. Bash script looks like:
```
# This script takes in a directory of excord .bed.gz files, and makes a single file with format:
# sampleID      Filename.Bed.gz

# I'll do that with this code:
shopt -s nullglob
DataDir=/mnt/common/OPEN_DATA/1kG_Trio/Excord_Output/
Files=($DataDir/*.bed.gz)

pedfile=$DataDir/AllSamples.ped
# Delete if it exists
rm $pedfile
# give it a header
echo "Sample    Sex     Alt_File" > $pedfile

for file in ${Files[@]};
do
        basefile=$(basename -- "$file")
        sampleID="${basefile%%.*}"
        echo $sampleID  $file   
        echo "$sampleID  $file" >> $pedfile     
done
```

That gives me a ped file that looks like this:
```
Sample	Alt_File
HG00403 /mnt/common/OPEN_DATA/1kG_Trio/Excord_Output//HG00403.bed.gz
HG00404 /mnt/common/OPEN_DATA/1kG_Trio/Excord_Output//HG00404.bed.gz
HG00405 /mnt/common/OPEN_DATA/1kG_Trio/Excord_Output//HG00405.bed.gz
...
```

### Make STIX database from giggle indexed output

Now back to STIX to make the database given the index directory, and the ped file.

```
Stix_SIF=/mnt/common/Precision/STIX/stix.sif

WorkingDir=/mnt/common/OPEN_DATA/1kG_Trio/
DataDir=$WorkingDir/Excord_Output/
SVDir=$WorkingDir/MantaSmoove/
IndexDir=$WorkingDir/STIX_Index/
PedFile=$DataDir/AllSamples.ped

# Initialize stix database with giggle index and bed files
singularity exec \
        -B $WorkingDir \
        -B $IndexDir \
        -B $DataDir \
        $Stix_SIF \
        stix \
        -i $IndexDir \
        -p $PedFile \
        -d $DataDir/AllSamples.stix.db \
        -c 2
```

And I get an error:
```
stix: ERROR ped_create_db(): PED file /mnt/common/OPEN_DATA/1kG_Trio/Excord_Output//HG00403.bed.gz not found in giggle index.
```

I have tried rerunning with different ped file columns too, and with only the base name in the created ped file, e.g. modified from above:
```
for file in ${Files[@]};
do
        basefile=$(basename -- "$file")
        sampleID="${basefile%%.*}"
        echo $sampleID  $basefile   
        echo "$sampleID  $basefile" >> $pedfile     
done
```

But still get error:
```
stix: ERROR ped_create_db(): PED file HG00404.bed.gz not found in giggle index.
```

Now I'm thinking that the giggle index is actually incomplete. When it ran, it only output that it had processed the number of lines for HG00403.bed.gz: 
```
Indexed 14992289 intervals.
```

Rerunning the giggle index, perhaps it's a matter of the placement of " in the bash script.
It now looks like this:
```
giggle index -s -f -o /mnt/common/OPEN_DATA/1kG_Trio/STIX_Index -i "/mnt/common/OPEN_DATA/1kG_Trio//Excord_Output/*.bed.gz"
```

We'll see if that works....




