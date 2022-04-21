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



