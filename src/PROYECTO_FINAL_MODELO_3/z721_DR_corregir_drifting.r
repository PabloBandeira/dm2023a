# Experimentos Colaborativos Default
# Workflow  Data Drifting repair

#require vm con
#   8 vCPU
#  64 GB  memoria RAM


#limpio la memoria
rm( list= ls(all.names= TRUE) )  #remove all objects
gc( full= TRUE )                 #garbage collection

require("data.table")
require("yaml")


#Parametros del script
PARAM  <- list()
PARAM$experimento  <- "DRv6"

PARAM$exp_input  <- "CAv1"

PARAM$variables_intrames  <- TRUE   # atencion esto esta en TRUE

#valores posibles  "ninguno" "rank_simple" , "rank_cero_fijo" , "deflacion"
PARAM$metodo  <- "rank_cero_fijo"

PARAM$home  <- "~/buckets/b1/"
# FIN Parametros del script

OUTPUT  <- list()


#------------------------------------------------------------------------------
#Esta es la parte que los alumnos deben desplegar todo su ingenio
#Agregar aqui sus PROPIAS VARIABLES manuales

AgregarVariables_IntraMes  <- function( dataset )
{
  gc()
  #INICIO de la seccion donde se deben hacer cambios con variables nuevas

  #creo un ctr_quarter que tenga en cuenta cuando los clientes hace 3 menos meses que estan
  dataset[  , ctrx_quarter_normalizado := ctrx_quarter ]
  dataset[ cliente_antiguedad==1 , ctrx_quarter_normalizado := ctrx_quarter * 5 ]
  dataset[ cliente_antiguedad==2 , ctrx_quarter_normalizado := ctrx_quarter * 2 ]
  dataset[ cliente_antiguedad==3 , ctrx_quarter_normalizado := ctrx_quarter * 1.2 ]

  #variable extraida de una tesis de maestria de Irlanda
  dataset[  , mpayroll_sobre_edad  := mpayroll / cliente_edad ]

  #se crean los nuevos campos para MasterCard  y Visa, teniendo en cuenta los NA's
  #varias formas de combinar Visa_status y Master_status
  dataset[ , vm_status01       := pmax( Master_status,  Visa_status, na.rm = TRUE) ]
  dataset[ , vm_status02       := Master_status +  Visa_status ]
  dataset[ , vm_status03       := pmax( ifelse( is.na(Master_status), 10, Master_status) , ifelse( is.na(Visa_status), 10, Visa_status) ) ]
  dataset[ , vm_status04       := ifelse( is.na(Master_status), 10, Master_status)  +  ifelse( is.na(Visa_status), 10, Visa_status)  ]
  dataset[ , vm_status05       := ifelse( is.na(Master_status), 10, Master_status)  +  100*ifelse( is.na(Visa_status), 10, Visa_status)  ]

  dataset[ , vm_status06       := ifelse( is.na(Visa_status), 
                                          ifelse( is.na(Master_status), 10, Master_status), 
                                          Visa_status)  ]

  dataset[ , mv_status07       := ifelse( is.na(Master_status), 
                                          ifelse( is.na(Visa_status), 10, Visa_status), 
                                          Master_status)  ]


  #combino MasterCard y Visa
  dataset[ , vm_mfinanciacion_limite := rowSums( cbind( Master_mfinanciacion_limite,  Visa_mfinanciacion_limite) , na.rm=TRUE ) ]

  dataset[ , vm_Fvencimiento         := pmin( Master_Fvencimiento, Visa_Fvencimiento, na.rm = TRUE) ]
  dataset[ , vm_Finiciomora          := pmin( Master_Finiciomora, Visa_Finiciomora, na.rm = TRUE) ]
  dataset[ , vm_msaldototal          := rowSums( cbind( Master_msaldototal,  Visa_msaldototal) , na.rm=TRUE ) ]
  dataset[ , vm_msaldopesos          := rowSums( cbind( Master_msaldopesos,  Visa_msaldopesos) , na.rm=TRUE ) ]
  dataset[ , vm_msaldodolares        := rowSums( cbind( Master_msaldodolares,  Visa_msaldodolares) , na.rm=TRUE ) ]
  dataset[ , vm_mconsumospesos       := rowSums( cbind( Master_mconsumospesos,  Visa_mconsumospesos) , na.rm=TRUE ) ]
  dataset[ , vm_mconsumosdolares     := rowSums( cbind( Master_mconsumosdolares,  Visa_mconsumosdolares) , na.rm=TRUE ) ]
  dataset[ , vm_mlimitecompra        := rowSums( cbind( Master_mlimitecompra,  Visa_mlimitecompra) , na.rm=TRUE ) ]
  dataset[ , vm_madelantopesos       := rowSums( cbind( Master_madelantopesos,  Visa_madelantopesos) , na.rm=TRUE ) ]
  dataset[ , vm_madelantodolares     := rowSums( cbind( Master_madelantodolares,  Visa_madelantodolares) , na.rm=TRUE ) ]
  dataset[ , vm_fultimo_cierre       := pmax( Master_fultimo_cierre, Visa_fultimo_cierre, na.rm = TRUE) ]
  dataset[ , vm_mpagado              := rowSums( cbind( Master_mpagado,  Visa_mpagado) , na.rm=TRUE ) ]
  dataset[ , vm_mpagospesos          := rowSums( cbind( Master_mpagospesos,  Visa_mpagospesos) , na.rm=TRUE ) ]
  dataset[ , vm_mpagosdolares        := rowSums( cbind( Master_mpagosdolares,  Visa_mpagosdolares) , na.rm=TRUE ) ]
  dataset[ , vm_fechaalta            := pmax( Master_fechaalta, Visa_fechaalta, na.rm = TRUE) ]
  dataset[ , vm_mconsumototal        := rowSums( cbind( Master_mconsumototal,  Visa_mconsumototal) , na.rm=TRUE ) ]
  dataset[ , vm_cconsumos            := rowSums( cbind( Master_cconsumos,  Visa_cconsumos) , na.rm=TRUE ) ]
  dataset[ , vm_cadelantosefectivo   := rowSums( cbind( Master_cadelantosefectivo,  Visa_cadelantosefectivo) , na.rm=TRUE ) ]
  dataset[ , vm_mpagominimo          := rowSums( cbind( Master_mpagominimo,  Visa_mpagominimo) , na.rm=TRUE ) ]

  #a partir de aqui juego con la suma de Mastercard y Visa
  dataset[ , vmr_Master_mlimitecompra:= Master_mlimitecompra / vm_mlimitecompra ]
  dataset[ , vmr_Visa_mlimitecompra  := Visa_mlimitecompra / vm_mlimitecompra ]
  dataset[ , vmr_msaldototal         := vm_msaldototal / vm_mlimitecompra ]
  dataset[ , vmr_msaldopesos         := vm_msaldopesos / vm_mlimitecompra ]
  dataset[ , vmr_msaldopesos2        := vm_msaldopesos / vm_msaldototal ]
  dataset[ , vmr_msaldodolares       := vm_msaldodolares / vm_mlimitecompra ]
  dataset[ , vmr_msaldodolares2      := vm_msaldodolares / vm_msaldototal ]
  dataset[ , vmr_mconsumospesos      := vm_mconsumospesos / vm_mlimitecompra ]
  dataset[ , vmr_mconsumosdolares    := vm_mconsumosdolares / vm_mlimitecompra ]
  dataset[ , vmr_madelantopesos      := vm_madelantopesos / vm_mlimitecompra ]
  dataset[ , vmr_madelantodolares    := vm_madelantodolares / vm_mlimitecompra ]
  dataset[ , vmr_mpagado             := vm_mpagado / vm_mlimitecompra ]
  dataset[ , vmr_mpagospesos         := vm_mpagospesos / vm_mlimitecompra ]
  dataset[ , vmr_mpagosdolares       := vm_mpagosdolares / vm_mlimitecompra ]
  dataset[ , vmr_mconsumototal       := vm_mconsumototal  / vm_mlimitecompra ]
  dataset[ , vmr_mpagominimo         := vm_mpagominimo  / vm_mlimitecompra ]

  #Aqui debe usted agregar sus propias nuevas variables
  #Agrego 31 variables 

  dataset[ , vfe_limiteconsumo :=   vm_mlimitecompra / mpayroll ]
  dataset[ , vfe_gasto_mas := vm_mconsumototal / mpayroll]
  dataset[ , vfe_gasto_mas_edad := vm_mconsumototal / mpayroll_sobre_edad]
    #creo un tipo cliente que tenga en cuenta cuando gasta mas de lo gana
  dataset[  , vfe_tipocliente := vfe_gasto_mas ]
  dataset[ vfe_gasto_mas < 0 , vfe_tipocliente := 0 ] #gasto menos de lo que gana
  dataset[ vfe_gasto_mas == 1 , vfe_tipocliente := 1 ] #gasto todo de lo que gana
  dataset[ vfe_gasto_mas > 0 , vfe_tipocliente := 2 ] #gasto mas de lo que gana
  
  dataset[ , vfe_gasto_pago := vmr_mpagado / vmr_mconsumototal ] #ratio de ratio gasto mas de lo que gana
  dataset[ , vfe_saldo_pago := vmr_msaldototal / vmr_mconsumototal ] #ratio Saldo vs consumo
  dataset[ , vfe_limiteloco :=  vmr_Visa_mlimitecompra / vmr_Master_mlimitecompra ] #ratio loco entre los limites de master y visa
  dataset[ , vfe_consumo_pagominimo :=  vm_cconsumos / vm_mpagominimo ] # Consumos vs pago minimo
  
  dataset[ , vfe_consumopesos_adelantopesos :=  vm_mconsumospesos / vm_madelantopesos ] # consumopesos sobre adelanto en pesos
  dataset[ , vfe_consumodolares_adelantodolares :=  vm_mconsumosdolares / vm_madelantodolares ] # Consumo en dolares vs adelanto en dolares
  dataset[ , vfe_fechadealta_iniciomora :=  vm_fechaalta / vm_Finiciomora ] # fecha de alta vs inicio de mora
  dataset[ , vfe_ultimocierre_Fvencimiento :=  vm_fultimo_cierre / vm_Fvencimiento ] # Ultimo cierre vs fecha vencimiento
  dataset[ , vfe_pagominimo_pagado :=  vm_mpagominimo / vm_mpagado ] # pago minimo vs pagado
  dataset[ , vfe_fechaalta_fultimo_cierre :=  vm_fechaalta / vm_fultimo_cierre ] # fecha de alta vs fecha ultimo cierre
  dataset[ , vfe_adelantoefectivo_pagominimo :=  vm_cadelantosefectivo / vm_mpagominimo ] # adelantos en efectivo vs pago minimo
  dataset[ , vfe_pagominimo_consumototal :=  vm_mpagominimo / vm_mconsumototal ] # pago minimo vs consumo total
  dataset[ , vfe_tarjetalimites_loco :=  Master_mlimitecompra/ Visa_mlimitecompra ] # limite_master vs limite visa
  dataset[ , vfe_limitecompra_consumodolares :=  vm_mlimitecompra / vm_mconsumosdolares ] # limite de compra vs consumo en dolares
  dataset[ , vfe_limitecompra_consumopesos :=  vm_mlimitecompra / vm_mconsumospesos ] # imite de compra vs consumo en pesos
  dataset[ , vfe_pminimo_consdolares :=  vm_mpagominimo / vm_mconsumosdolares ] # pago minimo vs consumo en dolares
  dataset[ , vfe_pminimo_conspesos :=  vm_mpagominimo / vm_mconsumospesos ] # pago minimo vs consumo en pesos
  dataset[ , vfe_fechaalta_fechaultimocierre :=  vm_fechaalta / vm_fultimo_cierre ] # Fecha de alta fecha ultimo cierre
  dataset[ , vfe_pago_pagominimo :=  vm_mpagado / vm_mpagominimo ] # pagado vs pagominimo
  dataset[ , vfe_limitecompra_payroll_edad :=  vm_mlimitecompra / mpayroll_sobre_edad ] # limitecomprea payroll sobre edad
  dataset[ , vfe_mpagominimo_payroll_edad :=  vm_mpagominimo / mpayroll_sobre_edad ] # Pago_minimo vs payroll_sobre_edad
  dataset[ , vfe_pagado_payroll_edad :=  vmr_mpagado / mpayroll_sobre_edad ] # monto pagado sobre vs payroll_sobre_edad
  dataset[ , vfe_consumos_payroll_edad :=  vm_cconsumos / mpayroll_sobre_edad ] # consumos vs payroll_sobre_edad
  dataset[ , vfe_pagosdol_payroll_edad :=  vm_mpagosdolares / mpayroll_sobre_edad ] # pagos en dolares vs payroll_sobre_edad
  dataset[ , vfe_pagospesos_payroll_edad :=  vm_mpagospesos / mpayroll_sobre_edad ] # pagos en pesos vs payroll_sobre_edad
  dataset[ , vfe_adelantopesos_payroll_edad :=  vm_madelantopesos / mpayroll_sobre_edad ] # adelantos en pesos vs payroll_sobre_edad
  dataset[ , vfe_adelantodolares_payroll_edad :=  vm_madelantodolares / mpayroll_sobre_edad ] # adelantos en dolares vs payroll_sobre_edad


  #valvula de seguridad para evitar valores infinitos
  #paso los infinitos a NULOS
  infinitos      <- lapply(names(dataset),function(.name) dataset[ , sum(is.infinite(get(.name)))])
  infinitos_qty  <- sum( unlist( infinitos) )
  if( infinitos_qty > 0 )
  {
    cat( "ATENCION, hay", infinitos_qty, "valores infinitos en tu dataset. Seran pasados a NA\n" )
    dataset[mapply(is.infinite, dataset)] <<- NA
  }


  #valvula de seguridad para evitar valores NaN  que es 0/0
  #paso los NaN a 0 , decision polemica si las hay
  #se invita a asignar un valor razonable segun la semantica del campo creado
  nans      <- lapply(names(dataset),function(.name) dataset[ , sum(is.nan(get(.name)))])
  nans_qty  <- sum( unlist( nans) )
  if( nans_qty > 0 )
  {
    cat( "ATENCION, hay", nans_qty, "valores NaN 0/0 en tu dataset. Seran pasados arbitrariamente a 0\n" )
    cat( "Si no te gusta la decision, modifica a gusto el programa!\n\n")
    dataset[mapply(is.nan, dataset)] <<- 0
  }

}
#------------------------------------------------------------------------------
#deflaciona por IPC
#momento 1.0  31-dic-2020 a las 23:59

drift_deflacion  <- function( campos_monetarios )
{
  vfoto_mes <- c( 201901, 201902, 201903, 201904, 201905, 201906,
                  201907, 201908, 201909, 201910, 201911, 201912,
                  202001, 202002, 202003, 202004, 202005, 202006,
                  202007, 202008, 202009, 202010, 202011, 202012,
                  202101, 202102, 202103, 202104, 202105, 202106,
                  202107  )

  vIPC  <- c( 1.9903030878, 1.9174403544, 1.8296186587,
              1.7728862972, 1.7212488323, 1.6776304408,
              1.6431248196, 1.5814483345, 1.4947526791,
              1.4484037589, 1.3913580777, 1.3404220402,
              1.3154288912, 1.2921698342, 1.2472681797,
              1.2300475145, 1.2118694724, 1.1881073259,
              1.1693969743, 1.1375456949, 1.1065619600,
              1.0681100000, 1.0370000000, 1.0000000000,
              0.9680542110, 0.9344152616, 0.8882274350,
              0.8532444140, 0.8251880213, 0.8003763543,
              0.7763107219  )

  tb_IPC  <- data.table( "foto_mes"= vfoto_mes,
                         "IPC" = vIPC )

  dataset[ tb_IPC,
           on= c("foto_mes"),
           (campos_monetarios) :=  .SD * i.IPC ,
           .SDcols = campos_monetarios ]

}

#------------------------------------------------------------------------------

drift_rank_simple  <- function( campos_drift )
{
  for( campo in campos_drift )
  {
    cat( campo, " " )
    dataset[ , paste0(campo,"_rank") :=  (frank( get(campo), ties.method="random") - 1) / ( .N -1 ), by= foto_mes]
    dataset[ , (campo) := NULL ]
  }
}
#------------------------------------------------------------------------------
#El cero se transforma en cero
#los positivos se rankean por su lado
#los negativos se rankean por su lado

drift_rank_cero_fijo  <- function( campos_drift )
{
  for( campo in campos_drift )
  {
    cat( campo, " " )
    dataset[ get(campo) ==0, paste0(campo,"_rank") := 0 ]
    dataset[ get(campo) > 0, paste0(campo,"_rank") :=   frank(  get(campo), ties.method="random")  / .N, by= foto_mes ]
    dataset[ get(campo) < 0, paste0(campo,"_rank") :=  -frank( -get(campo), ties.method="random")  / .N, by= foto_mes ]
    dataset[ , (campo) := NULL ]
  }
}
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#Aqui comienza el programa
PARAM$stat$time_start  <- format(Sys.time(), "%Y%m%d %H%M%S")

setwd("~/buckets/b1")

#cargo el dataset donde voy a entrenar
#esta en la carpeta del exp_input y siempre se llama  dataset.csv.gz
dataset_input  <- paste0( "./exp/", PARAM$exp_input, "/dataset.csv.gz" )
dataset  <- fread( dataset_input )

#creo la carpeta donde va el experimento
dir.create( paste0( "./exp/", PARAM$experimento, "/"), showWarnings = FALSE )
setwd(paste0( "./exp/", PARAM$experimento, "/"))   #Establezco el Working Directory DEL EXPERIMENTO

write_yaml( PARAM, file= "parametros.yml" )   #escribo parametros utilizados

#primero agrego las variables manuales
if( PARAM$variables_intrames )  AgregarVariables_IntraMes( dataset )

#ordeno de esta forma por el ranking
setorder( dataset, foto_mes, numero_de_cliente )

#por como armé los nombres de campos, estos son los campos que expresan variables monetarias
campos_monetarios  <- colnames(dataset)
campos_monetarios  <- campos_monetarios[campos_monetarios %like% "^(m|Visa_m|Master_m|vm_m)"]

#aqui aplico un metodo para atacar el data drifting
#hay que probar experimentalmente cual funciona mejor
switch( 
PARAM$metodo,
  "ninguno"        = cat( "No hay correccion del data drifting" ),
  "rank_simple"    = drift_rank_simple( campos_monetarios ),
  "rank_cero_fijo" = drift_rank_cero_fijo( campos_monetarios ),
  "deflacion"      = drift_deflacion( campos_monetarios ) 
)



fwrite( dataset,
        file="dataset.csv.gz",
        logical01= TRUE,
        sep= "," )

#------------------------------------------------------------------------------
PARAM$stat$time_end  <- format(Sys.time(), "%Y%m%d %H%M%S")
write_yaml( PARAM, file= "parametros.yml" )   #escribo parametros utilizados

#dejo la marca final
cat( format(Sys.time(), "%Y%m%d %H%M%S"),"\n",
     file= "zRend.txt",
     append= TRUE  )