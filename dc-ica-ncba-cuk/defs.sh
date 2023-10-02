OUTDIR=./generated-data

DC_URL=https://dev.data.solidarityeconomy.coop/dotcoop2023/standard.csv
DC_CSV=$OUTDIR/dc.csv 
DC_TB=dc
DC_FK=dcid

ICA_URL=https://dev.data.solidarityeconomy.coop/ica/standard.csv
ICA_CSV=$OUTDIR/ica.csv
ICA_TB=ica
ICA_FK=icaid

NCBA_URL=https://dev.data.solidarityeconomy.coop/ncba/standard.csv
NCBA_CSV=$OUTDIR/ncba.csv
NCBA_TB=ncba
NCBA_FK=ncbaid

CUK_URL=https://dev.data.solidarityeconomy.coop/coops-uk/standard.csv
CUK_CSV=$OUTDIR/cuk.csv 
CUK_TB=cuk
CUK_FK=cukid


DB=$OUTDIR/$DC_TB-$ICA_TB-$NCBA_TB-$CUK_TB.db
OUT_CSV=$OUTDIR/$DC_TB-$ICA_TB-$NCBA_TB-$CUK_TB.csv
