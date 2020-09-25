#!/bin/bash 

# Estableciendo las opciones, donde: 
# (1) Quiero que aparezca
# (0) No quiero que aparezca

        opcion_topografia=1
	opcion_iluminacion=1
	opcion_contorno=0
	opcion_escala_topo=1
	opcion_velocidad_relativa=0 	#para (0) se plotearan los vecotres velocidad horizontal

#################################################################
#para obtener las velocidades relativas respecto a una estacion, pedimos por pantalla elnombre de la estacion que uno quiere
if [ "${opcion_velocidad_relativa}" = 1 ]; then

echo "Elija una estacion"
read ESTACION

fi

#################################################################

region=california


#datos para generar el borde
proyeccion='M'14
ticks='a'2
cambioscolor='f'1
grilla='g'1
marco=$ticks$cambiacolor #$grilla
lon1=234
lon2=248
lat1=32
lat2=44
limites=$lon1/$lon2/$lat1/$lat2	
xshift="2.0"
yshift="10.0"
archivo='california.ps'
archivo2='california_sismos.ps'
#datos para el mapa

resolucion='h'  # Resolucion de las lineas de costa. Puedes elegir:
                # (f)ull, (h)igh, (i)ntermediate, (l)ow, y (c)rude

#lineas costeras
costa_espesor=0.3
rojo_costa=0
verde_costa=0
azul_costa=200
color_costa=$rojo_costa'/'$verde_costa'/'$azul_costa

#tipo de fronteras
fronteras='a'  	#con "a" se añaden todos los tipos de frontera 
front_espesor=0.2
rojo_front=0
verde_front=0
azul_front=0
color_front=$rojo_front'/'$verde_front'/'$azul_front


lagos="-C50/100/200 -A0/2/4"

#representacion rios #-I$tipo_rios/$espesor_rios,$color_rios
tipo_rios='a'
espesor_rios=0.3
rojo_rios=0
verde_rios=0
azul_rios=200
color_rios=$rojo_rios'/'$verde_rios'/'$azul_rios


#grillas
topografia='california1.grd'
iluminacion='california.int'
azimut=225

#paleta de color para la grilla
paleta=GMT_globe.cpt


#colores para el no uso de grilla
#color continente
rojo_cont=0
verde_cont=250
azul_cont=0
color_cont=$rojo_cont'/'$verde_cont'/'$azul_cont

#color oceanos
rojo_h2o=0
verde_h2o=0
azul_h2o=250
color_h2o=$rojo_h2o'/'$verde_h2o'/'$azul_h2o




#rosa de los vientos
rosa="-Tf-109.3/43/1.5c:w,e,s,n"


####################################################################
#MAPA BASE 


gmt psbasemap -J$proyeccion -B$marco -R$limites -P -V -X${xshift} -Y${yshift} -K >$archivo 

# Aplicando los condicionales:
if [ "${opcion_topografia}" = 1 ]; then # Cortando la grilla original a los limites establecidos. 


gmt grdcut ${topografia} -G${region}.grd -R${limites} -V 

	if [ "${opcion_iluminacion}" = 1 ]; then
	# Iluminando la grilla topografica generada en el grdcut desde un azimut 

	gmt grdgradient ${region}.grd -G${iluminacion} -A${azimut} -Nt -M
	# Graficando la topografia de la region seleccionada con su iluminacion:
	gmt grdimage ${region}.grd -C${paleta} -I${iluminacion} -B${marco} -J${proyeccion} -R${limites} -P -V -O -K >> ${archivo}

	else
        # Graficando la topografia de la region seleccionada sin iluminacion:
	gmt grdimage ${region}.grd -C${paleta} -B${marco} -J${proyeccion} -R${limites} -P -V -O -K >> ${archivo}
	fi


	if [ "${opcion_contorno}" = 1 ]; then
        # Graficando los contornos de la grilla:
	gmt grdcontour ${region}.grd -B${marco} -J${proyeccion} -C200 -A1000+k0/0/0 -R${limites} -P -V -W0.1p/0/0/0 -Gd10c -O -K >> ${archivo}
	fi


	if [ "${opcion_escala_topo}" = 1 ]; then
        # Construyendo la escala de colores a partir de la paleta seleccionada:
	gmt psscale  -D12c/-1c/4c/0.5ch -C${paleta} -Ba10000f5000/a10000f5000:"Topografia [m]": -O -K >> ${archivo}
	fi

# Graficando las costas y limites del mapa (para graficar las lineas de costa marinas): 
gmt pscoast -B${marco} -J${proyeccion} -R${limites} -P -V -D${resolucion} -W${costa_espesor},$color_costa -N$fronteras/$front_espesor,$color_front -I$tipo_rios/$espesor_rios,$color_rios -O -K $rosa >> ${archivo}

# Graficando las costas y limites del mapa (para incluir los lagos):
gmt pscoast -B${marco} -J${proyeccion} -R${limites} -P -V -D${resolucion} -W${costa_espesor},$color_costa ${bordes} ${lagos} -O -K >> ${archivo}

else

#Graficando la costa y limites del mapa con un solo color (sin uso de grillas)
gmt pscoast -J$proyeccion -B$marco -R$limites -D$resolucion -W$costa_espesor,$color_costa -N$fronteras/$front_espesor,$color_front -G$color_cont -S$color_h2o ${rosa}  -K -O -P  >>$archivo 


fi


#creamos una copia para graficar sismos y vectores en mapas distintos
cp $archivo $archivo2



###################################################################

#simicidad y fallas 
#descargamos archivo KML de https://earthquake.usgs.gov/hazards/qfaults/
kml=qfaults.kml		

gmt kml2gmt $kml  >fallas.xy 	#combertimos el archivo .kml a .xy notar que el archivo .xy va a quedar con un header para cada falla que va a servir para separar cada falla y que no lo considere como una sola falla gigante


#graficar fallas de color amarillo 

gmt psxy fallas.xy -J${proyeccion} -R${limites} -V -m -W0.01c,250/250/0 -O -K >> ${archivo2}



#Descargmos los archivos de simicidad historica de la zona de california en https://earthquake.usgs.gov/earthquakes/search/

sismos=query.csv 	#contine la sismicidad de la zona mayor a 5.0

#creamos una paleta acorde a los limites de nuestros datos
gmt makecpt -CGPS-Fire-Incandescent.cpt -T-10/200/1 -Z -I >profundidad.cpt


#ploteamos los datos de sismos (la cuarta columna representara el tamaño del circulo segun la magnitud del sismo)
more $sismos | awk -F "," '{print $3,$2,$4,($5*$5*$5/600)}'| gmt psxy -J$proyeccion -R${limites} -V -Sc -Cprofundidad.cpt -W0.1 -O -K >>$archivo2

#graficamos la escala de los sismos
gmt psscale  -D12c/-2.5c/4c/0.5ch -Cprofundidad.cpt  -Ba200f100/a-10f100:"Profundidad sismos[km]": -O -K >> ${archivo2}


#hacemos una layenda con la escala de las magnitudes y el tamaño del circulo 

echo -126 27 "Escala magnitudes" | gmt pstext -J -R -P -V -F+10fhelvetica_Bold,black+jLm -N -O -K >>$archivo2

echo "-125.5 26 100 0.854" | gmt psxy -J -R -Sc -Cprofundidad.cpt -N -W0.1 -O -K >>${archivo2} 

echo -124.8 26 "8.0 " | gmt pstext -J$proyeccion -R$limites -P -V -F+f10p,Helvetica,black+jLm -N -O -K  >>$archivo2

echo -125.5 25 100 0.571 | gmt psxy -J -R -Sc -Cprofundidad.cpt -N -W0.1 -O -K >>$archivo2

echo -124.8 25 "7.0" | gmt pstext -J$proyeccion -R$limites -P -V -F+f10p,Helvetica,black+jLm -N -O -K  >>$archivo2

 
echo -125.5 24 100 0.208 |gmt psxy -J -R -Sc -Cprofundidad.cpt -N -W0.1 -O -K >>${archivo2}

echo -124.8 24 "5.0" | gmt pstext -J$proyeccion -R$limites -P -V -F+f10p,Helvetica,black+jLm -N -O -K  >>$archivo2

######################################################################
#VECTORES  


#creamos un archivo .txt con solo los datos en la zona que estamos trabajando
more pbo_final_frame.csv| sed 's/,/\ /g' | sed "1,2 d" | awk '{if($5 <248 && $5 > 234)print $0}' | awk '{if($4 < 50 && $4 > 32)print $0}' >velocidades_california.txt



#aplicamos la condicional para velocidades
if [ "${opcion_velocidad_relativa}" = 1 ]; then


#guardaremos los datos de la estacion elegida como variables  
#velocidad norte de la estacion
v_norte=$(more velocidades_california.txt | awk -v estacion="$ESTACION" '$1==estacion' | awk '{print $7}')


#velocidad este de la estacion
v_este=$(more velocidades_california.txt  | awk -v estacion="$ESTACION" '$1==estacion' | awk '{print $8}')

#velocidad vertical de la estacion
v_vertical=$(more velocidades_california.txt | awk -v estacion="$ESTACION" '$1==estacion' | awk '{print $9}')


#longitud y latitud de la estacion
lonlat_estacion=$(more velocidades_california.txt | awk -v estacion="$ESTACION" '$1==estacion' | awk '{print $5, $4}')


#guardamos en un nuevo archivo las velocidades relativas de las otras estaciones respecto a la estacion elegida
more velocidades_california.txt | awk -v estacion="$ESTACION" '$1 != estacion'| awk '{print $0}' |awk -v vn="$v_norte" -v ve="$v_este" -v vz="$v_vertical"  '{print ($5,$4,$8-ve,$7-vn,$10,$11,$9-vz)}'>vrelativa_${ESTACION}.txt


#guardamos en un nuevo archivo las estaciones con velocidades verticales relativas positivas
more vrelativa_${ESTACION}.txt | awk '{if($7 > 0)print $0}' >vrelativa1_${ESTACION}.txt


#guardamos en un nuevo archivo las estaciones con velocidades verticales relativas negativas
more vrelativa_${ESTACION}.txt | awk '{if($7 < 0)print $0}' >vrelativa2_${ESTACION}.txt

#guardamos en un archivo las estaciones con velocidades relativas iguales a cero
more vrelativa_${ESTACION}.txt |awk '{if($7 ==0)print $0}' >vrelativa3_$ESTACION.txt


#ploteamos los vectores velocidad que tienen una velocidad relativa mayor a cero de color rojo 
gmt psvelo vrelativa1_${ESTACION}.txt -Se0.05/0.95/2 -A0.01/0.01/0.01 -W0.01 -Gred  -L -R -J -O -K -V >>${archivo}


#ploteamos los vectores velocidad que tienen una velocidad relativa menor a cero de color azul
gmt psvelo vrelativa2_${ESTACION}.txt -Se0.05/0.95/2 -A0.01/0.01/0.01 -W0.01 -Gblue  -L -R -J -O -K -V >>${archivo}

#ploteamos los vectores velocidad que tienen una velocidad relativa igual a cero de color blanco
gmt psvelo vrelativa3_${ESTACION}.txt -Se0.05/0.95/2 -A0.01/0.01/0.01 -W0.01 -Gwhite  -L -R -J -O -K -V >>${archivo}



#ploteamos la estacion elegida
echo $lonlat_estacion  | gmt psxy -J$proyeccion -R$limites -Sa0.7c -G153/0/153 -W0.2 -O -K -P -V >>$archivo


#ponemos una leyenda de la estacion elegida
echo -121 30 |  gmt psxy -J$proyeccion -R$limites -Sa0.5c -G153/0/153 -W0.2 -O -K -P -V -N >>$archivo

echo -120.6 30 "Estacion $ESTACION" |  gmt pstext -J$proyeccion -R$limites -P -V -F+f10p,Helvetica,black+jLm -N -O -K  >>$archivo


#ponemos leyenda de los vectores velocidad
echo -121.3 29.5 0 0.5 | gmt psxy -J -R -Sv0.3c+e -V -Gred -P -N -O -K >>$archivo

echo -120.6 29.5 "Velocidad vertical >0" |  gmt pstext -J$proyeccion -R$limites -P -V -F+f10p,Helvetica,black+jLm -N -O -K  >>$archivo



echo -121.3 29 0 0.5 | gmt psxy -J -R -Sv0.3c+e -V -P -N -Gblue -O -K >>$archivo

echo -120.6 29 "Velocidad vertical <0" |  gmt pstext -J$proyeccion -R$limites -P -V -F+f10p,Helvetica,black+jLm -N -O -K  >>$archivo



echo -121.3 28.5 0 0.5 | gmt psxy -J -R -Sv0.3c+e -V -P -N -O -Gwhite -K >>$archivo

echo -120.6 28.5 "Velocidad vertical =0" |  gmt pstext -J$proyeccion -R$limites -P  -F+f10p,Helvetica,black+jLm -N -O -K -V >>$archivo



#leyenda de escala de vectores
echo -126 27 "Escala vectores" | gmt pstext -J -R -P -V -F+10fhelvetica_Bold,black+jLm -N -O -K >>$archivo

echo -126 26 0  2 | gmt psxy -J -R -Sv0.3c+e -V -P -N -O -Gblack -K >>$archivo

echo -124 26 "40[mm/yr]" |gmt pstext -J -R -P -F+f10p,helvetica,black+jLm -N -O -K -V >>$archivo


echo -126 25.5 0 1.5 | gmt psxy -J -R -Sv0.3c+e -V -P -N -O -Gblack -K >>$archivo

echo -124 25.5 "30[mm/yr]" | gmt pstext -J -R -P -F+f10p,helvetica,black+jLm -N -O -K -V >>$archivo 



echo -126 25 0 1 |  gmt psxy -J -R -Sv0.3c+e -V -P -N -O -Gblack -K >>$archivo

echo -124 25 "20[mm/yr]" | gmt pstext -J -R -P -F+f10p,helvetica,black+jLm -N -O -K -V >>$archivo








else

#separamos las velocidades horizontales positivas y negativas

more velocidades_california.txt | awk '{if($8 >= 0)print $0}' >>vhorizontal_positiva.txt

more velocidades_california.txt | awk '{if($8 < 0)print $0}' >>vhorizontal_negativa.txt


#ploteamos las velocidades horizontales positivas con un angulo 0 
more vhorizontal_positiva.txt  | awk '{print $5,$4,0,$8*$8/1000}' | gmt psxy -K -O -Sv0.15c+e -V -Gblack -P -J -R >>$archivo

#ploteamos las velocidades negativas horizontales con un angulo de 180
more vhorizontal_negativa.txt  | awk '{print $5,$4,180,$8*$8/1000}' | gmt psxy -K -O -Sv0.15c+e -V -P -Gblack -J -R >>$archivo

#leyenda de escala de vectores
echo -126 27 "Escala vectores" | gmt pstext -J -R -P -V -F+10fhelvetica_Bold,black+jLm -N -O -K >>$archivo

echo -126 26 0  1.6 | gmt psxy -J -R -Sv0.3c+e -V -P -N -O -Gblack -K >>$archivo

echo -124 26 "40[mm/yr]" |gmt pstext -J -R -P -F+f10p,helvetica,black+jLm -N -O -K -V >>$archivo


echo -126 25.5 0 0.9 | gmt psxy -J -R -Sv0.3c+e -V -P -N -O -Gblack -K >>$archivo

echo -124 25.5 "30[mm/yr]" | gmt pstext -J -R -P -F+f10p,helvetica,black+jLm -N -O -K -V >>$archivo 


echo -126 25 0 0.4 |  gmt psxy -J -R -Sv0.3c+e -V -P -N -O -Gblack -K >>$archivo

echo -124 25 "20[mm/yr]" | gmt pstext -J -R -P -F+f10p,helvetica,black+jLm -N -O -K -V >>$archivo 





fi

#fin condicional





#######################################################################

#CIUDADES

#posicion los angeles
lon1=-118.6919205
lat1=34.0201613 

#posicion San francisco
lon2=-122.507812
lat2=37.7576792



#ploteamos los angeles con un triangulo verde
echo $lon1 $lat1 | gmt psxy -J$proyeccion -R$limites -St0.5c -G0/255/0 -W0.2 -O -K -P -V >>$archivo  


#leyenda los angeles
echo -121 30.5 | gmt psxy -J$proyeccion -R$limites -St0.5c -G0/255/0 -W0.2 -O -K -P -V -N >>$archivo  
echo -120.6 30.5 "Los Angeles" | gmt pstext -J$proyeccion -R$limites -P -V -F+f10p,Helvetica,black+jLm -N -O -K >>$archivo



# ploteamos san francisco con un rombo verde
echo $lon2 $lat2 | gmt psxy -J$proyeccion -R$limites -W0.2 -Sd0.5c -G0/255/0 -O -K -P  >>$archivo

#leyenda san francisco
echo -121 31 | gmt psxy -J$proyeccion -R$limites -W0.2 -Sd0.5c -G0/255/0 -O -K -P -V -N >>$archivo
echo -120.6 31 "San Francisco" | gmt pstext -J$proyeccion -R$limites -P -V -F+f10p,Helvetica,black+jLm -N -O -K  >>$archivo




#plot y leyendas de las ciudades para archivo de sismicidad
echo $lon1 $lat1 | gmt psxy -J$proyeccion -R$limites -St0.5c -G0/255/0 -W0.2 -O -K -P -V >>$archivo2  


echo -121 30.5 | gmt psxy -J$proyeccion -R$limites -St0.5c -G0/255/0 -W0.2 -O -K -P -V -N >>$archivo2  
echo -120.6 30.5 "Los Angeles" | gmt pstext -J$proyeccion -R$limites -P -V -F+f10p,Helvetica,black+jLm -N -O -K >>$archivo2



echo $lon2 $lat2 | gmt psxy -J$proyeccion -R$limites -W0.2 -Sd0.5c -G0/255/0 -O -K -P  >>$archivo2

echo -121 31 | gmt psxy -J$proyeccion -R$limites -W0.2 -Sd0.5c -G0/255/0 -O -K -P -V -N >>$archivo2
echo -120.6 31 "San Francisco" | gmt pstext -J$proyeccion -R$limites -P -V -F+f10p,Helvetica,black+jLm -N -O -K  >>$archivo2





####################################################################

#INDENT MAP

#ponemos como limites aproximadamente America del Norte para mostrar la area de estudio relativo al mundo
limites2=-170/-50/0/70

#graficamos el indent map
gmt pscoast -JM4c  -R$limites2 -Y-4.3 -X0 -Dc -G128 -S255 -O -K >>${archivo}
#creamos un cuadrado rojo que encierre los limites del area de estudio
echo ${limites} | sed 's/\// /g' | awk '{printf"%s %s\n %s %s\n %s %s\n %s %s\n %s %s\n", $1, $3, $2, $3, $2, $4, $1, $4, $1, $3}' | gmt psxy -R${limites2} -JM4c -A -W0.5p,255/0/0 -O >> ${archivo}



#hacemos lo mismo para el rchivo de simicidad
gmt pscoast -JM4c  -R$limites2 -Y-4.3 -X0 -Dc -G128 -S255 -O -K >>${archivo2}

echo ${limites} | sed 's/\// /g' | awk '{printf"%s %s\n %s %s\n %s %s\n %s %s\n %s %s\n", $1, $3, $2, $3, $2, $4, $1, $4, $1, $3}' | gmt psxy -R${limites2} -JM4c -A -W0.5p,255/0/0 -O >> ${archivo2}

########################################################################

#Conversion de nuestro archivo .ps a .pdf y .png

#hace la conversion de .ps a .pdf papersize es el tamaño del papel, optimize optimiza el pdf creado embedallfonts hace que las fuentes se vean siempre
ps2pdf -sPAPERSIZE=a4 -dOptimize=true -dEmbedAllFonts=true $archivo 				

#hace la conversion de .ps a .png
gmt ps2raster $archivo -A -Tg -V        



#Lo repetimos para el archivo de simicidad 

ps2pdf -sPAPERSIZE=a4 -dOptimize=true -dEmbedAllFonts=true $archivo2 				

gmt ps2raster $archivo2 -A -Tg -V        





