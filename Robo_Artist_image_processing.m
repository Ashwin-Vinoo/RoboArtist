%% PROGRAM FOR DRAWING THE OUTLINE OF AN IMAGE VIA A 4 STAGE AX-12A BASED ROBOTIC ARM.THE IMAGE IS OBTAINED FROM A SPECIFIED LOCATION OR THROUGH 
%% A HD CAMERA. IT IS PROCESSED BUY AN EDGE DETECTION ALGORITHM AND THE SERVO ANGLE DATA IS SENT TO THE SERVO CONTROLLING ARDUINO MICROCONTROLLER 
%% THROUGH SERIAL COMMUNICATION AT A PREDETERMINED BAUDRATE.
clear all;     % Removes the memory of earlier used variables from the workspace
pause on;                                   % Enables the pause function
cmap=colormap(gray(256));                   % Colormap needed for representing grayscale images
close all force;                            % Closes all figures
x='D:\Desktop\Creative';     % Location containing the image file
y='JPEG';                                   % Format of the above image file
mkdir('C:\Users\vaio\Desktop\results');     % Makes the results folder to store all the image files formed during program execution
clc;                                        % Clears the command window
i=input('Enter 0(zero) to communicate with Arduino via USB cable or Enter any other value to use bluetooth module:');
if(i==0)
    j=strcat('COM',int2str(input('Enter the Serial port COM Number:')));
    k=input('Enter the Serial communication baudrate:');
    ser=serial(j,'BaudRate',k);           % Sets the baudrate for serial communication to arduino at the given COM port
else
    ser=Bluetooth('HC-06',1);
end;
fopen(ser);                               % Opens serial communication to the arduino (8 bit data,1 start bit and 1 stop bit)
disp(ser);                                % Displays data on the serial communications port
pause(2);                                 % Wait for three seconds for arduino to reset after opening serial communication
fwrite(ser,50,'uint8');                   % Sends 50 to the arduino to let it know matlab code is executing
%% OBTAINING THE IMAGE TO BE PROCESSED FROM AN IMAGE FILE OR CAMERA
disp('IMAGE AQUISITION PROCESS INITIATED....');
flag=input('To obtain the image through the camera,Enter 0(zero).To open the specified image file,Enter any other value:');
if(flag==0)    
    vid = videoinput('winvideo',1,'YUY2_1280x1024');  % Creates a video object vid of winvideo format having a camera ID of 1 and a 1280(number of columns)x1024(number of rows)    
    src=getselectedsource(vid);                       % Enables the user to vary the camera parameters
    src.Brightness=50;                                % Changes the brightness of the camera image
    src.Saturation=100;                               % Changes the saturation of the camera image
    get(vid);                                         % Displays details of the camera parameters  
    get(src)                                          % It also displays details of the camera parameters                                
    imaqhwinfo                                        % Displays details of available camera adaptors
    imaqhwinfo('winvideo',1)                          % Displays details of the winvideo based camera of ID 1
    disp('Press any key to continue');                % disp() display's text on the matlab command window
    pause;                                            % Pauses operation until a key is pressed
    while (flag==0)
        clc;   
        preview(vid);                                          % Allows the user to view streamed video
        disp('Enter any key to take a snapshot');
        pause;                                                 % Pause till a key is pressed                       
        a=getsnapshot(vid);                                    % Returns a camera video frame                                      
        disp('Snapshot image has been succesfully obtained');
        closepreview(vid);                                     % Closes the preview of video stream
        c=single(ycbcr2rgb(a));                                % Converts the received YCBCR image to RGB with single(float)resolution
        imtool(c);                                             % Allows the RGB image to be viewed and examined
        flag=input('To repeat photoshoot,Enter 0(zero):');     % input() function input's data from the user at the command window
        close all;
    end;
    delete(vid);
else
    c=(imread(x,y));                                                   % Location where your JPEG(Joint photographic experts group) image is stored  
    fprintf('Image succesfully retrieved from the location:%s\n',x);   % fprintf can be used for disp(sprintf()),where sprintf creates a string (%s means string,%d means decimal and \n is the newline metacharacter)    
    imagesc(c);                                                        % Similar to imtool(),but can't examine the figure's pixel coardinates and values   
    title('Retrieved image');                                          % Gives a title to the image displayed
    c=single(c);
    disp('The image selected is as shown,Press any key to continue...');
    pause;   
    close all;                                                         % Close the above figure
end;
[dim1,dim2,i]=size(c);      % Stores the image dimensions in dim1 and dim2 (3 is stored in i)
a=c(1:dim1,1:dim2,1);    
b=c(1:dim1,1:dim2,2);       % Seperates the dim1xdim2x3 image into 3 different matrices of dim1xdim2 size
c=c(1:dim1,1:dim2,3);    
%% PERFORMING 2D CONVOLUTION WITH A 5X5 GAUSSIAN FILTER (IMAGE BLURRING)
disp('IMAGE BLURRING PROCESS INITIATED....');
i=1;                % Number of times convolution is repeated
j=5;                % Increase for obtaining sharper Gaussian filters
k=[1.^j,2.^j,2.2360.^j,2.^j,1.^j;2.^j,2.6458.^j,2.8284.^j,2.6458.^j,2.^j;2.2360.^j,2.8284.^j,3.^j,2.8284.^j,2.2360.^j;2.^j,2.6458.^j,2.8284.^j,2.6458.^j,2.^j;1.^j,2.^j,2.2360.^j,2.^j,1.^j];  % Defines the Gaussian filter
start=0;                               % Each time 2D convoltion with a 5x5 Gaussian filter is performed 2 extra pixels are added at the sides of the image which are uneeded and removed using start variable
while(i~=0)
    a=conv2(a,k)/sum(k(:));
    b=conv2(b,k)/sum(k(:));            % 2D convolution is performed and the result is divided by the sum of elements in the Gaussian filter for averaging the result
    c=conv2(c,k)/sum(k(:));
    start=start+floor(max(size(k))/2); % Needed to negate matrix size increase due to convolution for the scanning process
    i=i-1;
end;
z(:,:,1)=uint8(a);
z(:,:,2)=uint8(b);
z(:,:,3)=uint8(c);
imwrite(z,'C:\Users\vaio\Desktop\results\Image_blurring_result.jpg','jpeg');
%% PERFORMING VERTICAL AND HORIZONTAL SCANNING AND ORIENTATION DECISION
disp('VERTICAL AND HORIZONTAL SCANNING AND ORIENTATION DECISION OPERATIONS INITIATED....');
k=90;                       % Adaptive factor(increase for getting sharper scanned images)
v=zeros(dim1,dim2);         % Matrix that represents the vertical change across all the pixels of the image
h=zeros(dim1,dim2);         % Matrix that represents the horizontal change across all the pixels of the image
d1=zeros(dim1,dim2);        % Matrix that represents the diagonal_1 change across all the pixels of the image
d2=zeros(dim1,dim2);        % Matrix that represents the diagonal_2 change across all the pixels of the image
orien=zeros(dim1,dim2);     % Matrix with values 1,2,3,4 that represents the direction along which maximum change has occured for each pixel
% VERTICAL SCANNING
for j=(start+1):(dim2+start)
    sa=a(start+1,j);                    % sa,sb and sc are variables storing a measure of the change of pixel values along the vertical direction
    sb=b(start+1,j);
    sc=c(start+1,j);                    % Vertical scanning stores the vertical change of pixel values of the R,G and B component matrices in v matrix
    for i=(start+1):(dim1+start)                
        sa=(k*a(i,j)+(100-k)*sa)/100;
        sb=(k*b(i,j)+(100-k)*sb)/100;        
        sc=(k*c(i,j)+(100-k)*sc)/100;  
        v(i-start,j-start)=abs(a(i,j)-sa)+abs(b(i,j)-sb)+abs(c(i,j)-sc); 
    end;
end;
% HORIZONTAL SCANNING
for i=(start+1):(dim1+start)
    sa=a(i,start+1);
    sb=b(i,start+1);
    sc=c(i,start+1);                    % Horizontal scanning stores the Horizontal change of pixel values of the R,G and B component matrices in h matrix
    for j=(start+1):(dim2+start)
        sa=(k*a(i,j)+(100-k)*sa)/100;
        sb=(k*b(i,j)+(100-k)*sb)/100;        
        sc=(k*c(i,j)+(100-k)*sc)/100;     
        h(i-start,j-start)=abs(a(i,j)-sa)+abs(b(i,j)-sb)+abs(c(i,j)-sc);
    end;
end;
% D1 SCANNING
for j=(start+1):(dim2+start)
    i=(start+1);
    sa=a(i,j);
    sb=b(i,j);
    sc=c(i,j);                             
    while(i<=(dim1+start) && j<=(dim2+start))
        sa=(k*a(i,j)+(100-k)*sa)/100;
        sb=(k*b(i,j)+(100-k)*sb)/100;        
        sc=(k*c(i,j)+(100-k)*sc)/100;
        d1(i-start,j-start)=abs(a(i,j)-sa)+abs(b(i,j)-sb)+abs(c(i,j)-sc);
        i=i+1;
        j=j+1;
    end;
end;                                   % Diagonal_1 scanning stores the diagonal_1 change of pixel values of the R,G and B component matrices in d1 matrix
for i=(start+2):(dim1+start)
    j=(start+1);
    sa=a(i,j);
    sb=b(i,j);
    sc=c(i,j);    
    while(i<=(dim1+start) && j<=(dim2+start))
        sa=(k*a(i,j)+(100-k)*sa)/100;
        sb=(k*b(i,j)+(100-k)*sb)/100;        
        sc=(k*c(i,j)+(100-k)*sc)/100;
        d1(i-start,j-start)=abs(a(i,j)-sa)+abs(b(i,j)-sb)+abs(c(i,j)-sc);
        i=i+1;
        j=j+1;
    end;
end;
% D2 SCANNING
for j=(start+1):(dim2+start)
    i=(dim1+start);
    sa=a(i,j);
    sb=b(i,j);
    sc=c(i,j);    
    while(i>=(start+1) && j<=(dim2+start))
        sa=(k*a(i,j)+(100-k)*sa)/100;
        sb=(k*b(i,j)+(100-k)*sb)/100;        
        sc=(k*c(i,j)+(100-k)*sc)/100;
        d2(i-start,j-start)=abs(a(i,j)-sa)+abs(b(i,j)-sb)+abs(c(i,j)-sc);
        i=i-1;
        j=j+1;
    end;
end;                                  % Diagonal_2 scanning stores the diagonal_2 change of pixel values of the R,G and B component matrices in d2 matrix
for i=(start+1):(dim1+start-1)
    j=(start+1);
    sa=a(i,j);
    sb=b(i,j);
    sc=c(i,j);    
    while (i>=(start+1) && j<=(dim2+start))
        sa=(k*a(i,j)+(100-k)*sa)/100;
        sb=(k*b(i,j)+(100-k)*sb)/100;        
        sc=(k*c(i,j)+(100-k)*sc)/100;
        d2(i-start,j-start)=abs(a(i,j)-sa)+abs(b(i,j)-sb)+abs(c(i,j)-sc);
        i=i-1;
        j=j+1;
    end;
end; 
% ORIENTATION DECISION
for i=1:dim1
    for j=1:dim2
        k=max([v(i,j),h(i,j),(d1(i,j)/sqrt(2)),(d2(i,j)/sqrt(2))]);           % Finds the direction of maximum change for a pixel at (i,j) position   
        if(k==v(i,j))
            orien(i,j)=1;               % Orien(i,j)=1 means that maximum change around (i,j) pixel is along the vertical direction
        elseif(k==h(i,j))
            orien(i,j)=2;               % Orien(i,j)=2 means that maximum change around (i,j) pixel is along the horizontal direction
        elseif(k==(d1(i,j)/sqrt(2)))
            orien(i,j)=4;               % Orien(i,j)=3 means that maximum change around (i,j) pixel is along the diagonal_1 direction
        elseif(k==(d2(i,j)/sqrt(2)))
            orien(i,j)=9;               % Orien(i,j)=4 means that maximum change around (i,j) pixel is along the diagonal_2 direction
        end;
    end;
end;
imwrite(v,'C:\Users\vaio\Desktop\results\Vertical_scanning.bmp','bmp');
imwrite(h,'C:\Users\vaio\Desktop\results\Horizontal_scanning.bmp','bmp');     % imwrite() stores the matrix in the specified directory in the specified format
imwrite(d1,'C:\Users\vaio\Desktop\results\Diagonal1_scanning.bmp','bmp');     % Note that bmp means bit map
imwrite(d2,'C:\Users\vaio\Desktop\results\Diagonal2_scanning.bmp','bmp');
imwrite((28.3333*orien),cmap,'C:\Users\vaio\Desktop\results\Orientation_result.png','BitDepth',8);    % To store a grayscale image , PNG(portable network graphics) is used and a bitdepth is specified based on the number of levels in the colormap
z=(sqrt(v.^2+h.^2)+sqrt(d1.^2+d2.^2))/2;                                        % Matrix that represents the total change across each pixel
%% PERFORMING VERTICAL AND HORIZONTAL THINNING
disp('VERTICAL AND HORIZONTAL THINNING PROCESS INITIATED....');
t=0.45;                               % Threshold value below which no pixel of z matrix is considered 
v=zeros(dim1,dim2);                   % zeros(dim1,dim2) returns an dim1xdim2 matrix of all 0's
for i=2:dim1-1
    for j=2:dim2-1                    % Thinning is done to get an single pixel thick well defined edge boundry using z and orien matrices
        k=z(i,j);
        if(k>=t&&i~=2&&j~=2)                        % z(i,j) must be greater than the threshold value
            if(orien(i,j)==1)                       % VERTICAL THINNING
                if(k>=z(i+1,j) && k>=z(i-1,j))      % z(i,j) must be greater than the adjacent pixels lying along the vertical axis
                    v(i,j)=1;                       % Selected pixels are converted to ones
                end;
            elseif(orien(i,j)==2)                   % HORIZONTAL THINNING
                if(k>=z(i,j+1) && k>=z(i,j-1))      % z(i,j) must be greater than the adjacent pixels lying along the horizontal axis
                    v(i,j)=1;
                end;            
            elseif(orien(i,j)==4)                   % DIAGONAL1 THINNING
                if(k>=z(i+1,j+1) && k>=z(i-1,j-1))  % z(i,j) must be greater than the adjacent pixels lying along diagonal1 
                    v(i,j)=1;
                end;             
            elseif(orien(i,j)==9)                   % DIAGONAL2 THINNING
                if(k>=z(i+1,j-1) && k>=z(i-1,j+1))  % z(i,j) must be greater than the adjacent pixels lying along diagonal2 
                    v(i,j)=1;
                end;  
            else
                v(i,j)=0;             % All pixels which are not selected by the thinning process are converted to zeros
            end;
        end;
    end;
end;
imwrite(v,'C:\Users\vaio\Desktop\results\Thinning_result.bmp','bmp');
%% PERFORMING 3 POINT REMOVAL PROCESS
disp('3 POINT REMOVAL PROCESS INITIATED....');
x=1;                          % x variable is used to search whether any operations have been performed during a cycle of the while loop
while(x~=0)                   % 3 point removal process removes any brancing of the edge and other irregularities obtained from thinning
    x=0;
    for i=2:dim1-1            % This section removes node pixels 1,1,1,1,1 
        for j=2:dim2-1        %                                  0,0,1,0,0
            if(v(i,j)==1)     %                                  0,0,0,0,0 Here the central 1 is a node pixel           
                if(v(i+1,j-1)==1)
                    if(v(i,j-1)+v(i-1,j-1)==2||v(i+1,j)+v(i+1,j+1)==2||v(i+1,j)+v(i,j-1)==2)
                        v(i,j)=0;
                    end
                elseif(v(i-1,j+1)==1)
                    if(v(i+1,j+1)+v(i,j+1)==2||v(i-1,j-1)+v(i-1,j)==2)
                        v(i,j)=0;
                    end;
                end;
            end;
        end;
    end;
    for i=2:dim1-1            % This section removes branching pixels 1,1,0,1,0
        for j=2:dim2-1        %                                       0,0,1,0,1
            if(v(i,j)==1)     %                                       0,1,1,0,0 Here the central 1 is a branching pixel and causes branching at that point  
                if((abs(v(i+1,j-1)-v(i+1,j))+abs(v(i+1,j)-v(i+1,j+1))+abs(v(i+1,j+1)-v(i,j+1))+abs(v(i,j+1)-v(i-1,j+1))+abs(v(i-1,j+1)-v(i-1,j))+abs(v(i-1,j)-v(i-1,j-1))+abs(v(i-1,j-1)-v(i,j-1))+abs(v(i,j-1)-v(i+1,j-1)))>=6);   % The number of times change occures in the adjacent outer 8 pixels of v(i,j)
                    v(i,j)=0;
                    x=x+1;
                end;
            end;
        end;
    end;
end;
imwrite(v,'C:\Users\vaio\Desktop\results\3_point_removal_result.bmp','bmp');
%% PERFORMING LINE END DETECTION AND SINGLE PIXEL ELIMINATION
disp('LINE END DETECTION AND SINGLE PIXEL ELIMINATION PROCESS INITIATED....');
endcount=0;     %Total number of end point pixels
totalcount=0;   %Total number of pixels along the path
h=zeros(dim1,dim2);
for i=2:dim1-1
    for j=2:dim2-1
        if(v(i,j)==1)                     % Since both an endpoint and a single pixel have a 1 value
            totalcount=totalcount+1;      % Totalcount must be incremented each time a pixel of value 1 is found
            k=abs(v(i+1,j-1)-v(i+1,j))+abs(v(i+1,j)-v(i+1,j+1))+abs(v(i+1,j+1)-v(i,j+1))+abs(v(i,j+1)-v(i-1,j+1))+abs(v(i-1,j+1)-v(i-1,j))+abs(v(i-1,j)-v(i-1,j-1))+abs(v(i-1,j-1)-v(i,j-1))+abs(v(i,j-1)-v(i+1,j-1));   % The number of times change occures in the adjacent outer 8 pixels of v(i,j)
            if(k==2)                             
                h(i,j)=1;                 % This pixel is an line end point
                endcount=endcount+1;      % Endcount must be incremented by one since an end point was found
            elseif(k==0)
                v(i,j)=0;                 % This pixel is a single pixel and is eliminated
                totalcount=totalcount-1;  % totalcount must be decremented by 1 since the single pixel was eliminated
            end;
        end;        
    end;
end;
imwrite((50*v+205*h),cmap,'C:\Users\vaio\Desktop\results\Line_end_detection_result.png','BitDepth',8);   % For imwrite involving PNG images , maximum value of input matrix should be (2.^bitdepth-1) 
%% PERFORMING CLOSE END'S JOINING OPERATION
disp('CLOSE ENDS JOINING OPERATION INITIATED....');
flag=input('To enable joining of close differently oriented end points(may cause more noise),Enter 0(zero):');
for k=1:2
    for i=2:dim1-1                     % This operation joins two nearby end points to increase the overall length of the segments to which these end points belong 
        for j=2:dim2-1                   
            if(v(i,j)==0)
                if(((h(i+1,j-1)==1)+(h(i+1,j)==1)+(h(i+1,j+1)==1)+(h(i,j+1)==1)+(h(i-1,j+1)==1)+(h(i-1,j)==1)+(h(i-1,j-1)==1)+(h(i,j-1)==1))==2)     % 2 endpoint pixels must be around pixel (i,j)
                    if((v(i+1,j)-h(i+1,j))==0 && (v(i,j+1)-h(i,j+1))==0 && (v(i-1,j)-h(i-1,j))==0 && (v(i,j-1)-h(i,j-1))==0)                         % The pixels at the sides of v+h(i,j) must be 2's or 0's
                        d2=h(i+1,j+1)*orien(i+1,j+1)+h(i,j+1)*orien(i,j+1)+h(i-1,j+1)*orien(i-1,j+1)+h(i-1,j)*orien(i-1,j)+h(i-1,j-1)*orien(i-1,j-1)+h(i,j-1)*orien(i,j-1)+h(i+1,j-1)*orien(i+1,j-1)+h(i+1,j)*orien(i+1,j);                        % Sum of orientations of surrounding 8 pixels         
                        if(d2==2||d2==4||d2==8||d2==18||k==2)     % The first 4 conditions is to check whether the orientations of the two endpoints are the same.k=2 is to allow connection of end points of even different orientations 
                            if((abs(h(i+1,j-1)-h(i+1,j))+abs(h(i+1,j)-h(i+1,j+1))+abs(h(i+1,j+1)-h(i,j+1))+abs(h(i,j+1)-h(i-1,j+1))+abs(h(i-1,j+1)-h(i-1,j))+abs(h(i-1,j)-h(i-1,j-1))+abs(h(i-1,j-1)-h(i,j-1))+abs(h(i,j-1)-h(i+1,j-1)))==4)       % The number of times change occures in the adjacent outer 8 pixels of h(i,j) is 4
                                if((abs(v(i+1,j-1)-v(i+1,j))+abs(v(i+1,j)-v(i+1,j+1))+abs(v(i+1,j+1)-v(i,j+1))+abs(v(i,j+1)-v(i-1,j+1))+abs(v(i-1,j+1)-v(i-1,j))+abs(v(i-1,j)-v(i-1,j-1))+abs(v(i-1,j-1)-v(i,j-1))+abs(v(i,j-1)-v(i+1,j-1)))==4)   % The number of times change occures in the adjacent outer 8 pixels of v(i,j) is 4
                                    v(i,j)=1;                     % If a pixel satisfies the above conditions,it is made 1 and acts as a bridge between two different line segments
                                    totalcount=totalcount+1;      % totalcount is increased by 1 since v(i,j) is made 1 from initial value of 0
                                    endcount=endcount-2;          % Since two end points are joined , endcount must be decreased by 2                
                                    for x=-1:1
                                        for y=-1:1
                                            if(h(i+x,j+y)==1)     % Searches the surrounding 9 pixels of h(i,j) and makes those with value one 0
                                                h(i+x,j+y)=0;     % Since two end points are joined they are no longer endpoints and must be made 0  
                                            end;
                                        end;
                                    end;
                                end;
                            end;
                        end;
                    end;                 % Let 1 denote line pixels and 2 denote endpoint pixels 120010
                end;                     %     Consider the representation of a part of v+h      000211 
            end;                         %                                                       000001 Here the central 0 and the two 2's are made 1
        end;
    end;
    if(flag~=0)                          % Breaks the for loop at the end of the first round(k=1) if flag is not zero
        break;                           % exits the current for/while loop operation
    end;
end;
imwrite((50*v+205*h),cmap,'C:\Users\vaio\Desktop\results\Close_ends_joining_result.png','BitDepth',8); 
d1=v;                                    % Stores v in d1 as v is manipulated and removed during line tracing
v=v+h;                                   % v is a matrix having 2 at endpoint pixels,1 at line/loop pixels and 0 at all the points not selected during thinning
%% PERFORMING LINE TRACING     
disp('LINE TRACING PROCESS INITIATED....');
a=2;         % Searching distance
b=2;         % Denotes open Line(2) or closed loop(1) Tracing
c=0;         % Counts the end point pixel's till endcount
i=1;j=1;     % Starting location for trace
d2=0;        % used to find closed loop starting and ending points 
pixel=0;     % counts all pixels scanned
while(pixel<totalcount)
    k=1;                  % k=1 means that the loop is searching for a suitable pixel and k=0 means a suitable pixel has been found and searching distance a is made 1 
    if(a==1)              % a=1 means that a search is initiated in the 8 pixels around the previous pixel
        if(v(i+1,j)>=1)          % Checks if the pixel above the current pixel has a value 1 or 2(for endpoints)
            k=0;                 % k=0 means that the search is over for this round of the while loop
            i=i+1;               % The value of i and j must be made that of the detected pixel
            pixel=pixel+1;       % pixel must be incremented each time a new pixel of value 1 is discovered              
            data1(pixel)=i;      % data1() contains the row number of the traversed pixels
            data2(pixel)=j;      % data2() contains the column number of the traversed pixels
                if(v(i,j)==2)    % If pixel at (i,j) is an end point
                    c=c+1;       % If and end point is discovered c must be incremented by 1
                end; 
            v(i,j)=0;            % The detected pixel must be removed so that it is'nt encountered again
        elseif(v(i,j+1)>=1)      % Checks if the pixel on the right of the current pixel has a value 1 or 2(for endpoints)
            k=0;
            j=j+1;
            pixel=pixel+1;               
            data1(pixel)=i;
            data2(pixel)=j;
                if(v(i,j)==2)
                    c=c+1;
                end; 
            v(i,j)=0;  
        elseif(v(i-1,j)>=1)      % Checks if the pixel below the current pixel has a value 1 or 2(for endpoints)
            k=0;
            i=i-1;
            pixel=pixel+1;               
            data1(pixel)=i;
            data2(pixel)=j;
                if(v(i,j)==2)
                    c=c+1;
                end; 
            v(i,j)=0; 
        elseif(v(i,j-1)>=1)      % Checks if the pixel on the left of the current pixel has a value 1 or 2(for endpoints)
            k=0;
            j=j-1;
            pixel=pixel+1;               
            data1(pixel)=i;
            data2(pixel)=j;
                if(v(i,j)==2)
                    c=c+1;
                end; 
            v(i,j)=0;             
        elseif(v(i+1,j+1)>=1)    % Checks if the pixel on the upper right side of the current pixel has a value 1 or 2(for endpoints)
            k=0;
            i=i+1;
            j=j+1;
            pixel=pixel+1;               
            data1(pixel)=i;
            data2(pixel)=j;
                if(v(i,j)==2)
                    c=c+1;
                end; 
            v(i,j)=0; 
        elseif(v(i-1,j+1)>=1)    % Checks if the pixel on the lower right side of the current pixel has a value 1 or 2(for endpoints)
            k=0;
            i=i-1;
            j=j+1;
            pixel=pixel+1;               
            data1(pixel)=i;
            data2(pixel)=j;
                if(v(i,j)==2)
                    c=c+1;
                end; 
            v(i,j)=0;             
        elseif(v(i-1,j-1)>=1)    % Checks if the pixel on the lower left side of the current pixel has a value 1 or 2(for endpoints)
            k=0;
            i=i-1;
            j=j-1;
            pixel=pixel+1;               
            data1(pixel)=i;
            data2(pixel)=j;
                if(v(i,j)==2)
                    c=c+1;
                end; 
            v(i,j)=0; 
        elseif(v(i+1,j-1)>=1)    % Checks if the pixel on the upper left side of the current pixel has a value 1 or 2(for endpoints)
            k=0;
            i=i+1;
            j=j-1;
            pixel=pixel+1;               
            data1(pixel)=i;
            data2(pixel)=j;
                if(v(i,j)==2)
                    c=c+1;
                end; 
            v(i,j)=0; 
        end;
    else                        % Executed if the searching distance is greater than 1                  
        if(k==1)
            y=a;
            for x=-a:a            
                if((i+x)>0 && (j+y)>0 && (i+x)<=dim1 && (j+y)<=dim2 && v(i+x,j+y)==b)  % Searches to the right of the current pixel(i,j) at a row 'a' distance away for any pixel of value b
                    k=0;
                    a=1;
                    i=i+x;
                    j=j+y;               
                    pixel=pixel+1;               
                    data1(pixel)=i;
                    data2(pixel)=j;
                    if(v(i,j)==2)
                        c=c+1;
                    end; 
                    v(i,j)=0;  
                    break;
                end;
            end; 
        end;     
        if(k==1)    % If no suitable pixel has still been found , execute the search below
            x=a;
            for y=-a:a
                if((i+x)>0 && (j+y)>0 && (i+x)<=dim1 && (j+y)<=dim2 && v(i+x,j+y)==b)  % Searches above the current pixel(i,j) at a row 'a' distance away for any pixel of value b
                    k=0;
                    a=1;
                    i=i+x;
                    j=j+y;               
                    pixel=pixel+1;               
                    data1(pixel)=i;
                    data2(pixel)=j;
                    if(v(i,j)==2)
                        c=c+1;
                    end; 
                    v(i,j)=0;  
                    break;
                end;
            end;
        end;
        if(k==1)   % If no suitable pixel has still been found , execute the search below
            y=-a;
            for x=-a:a
                if((i+x)>0 && (j+y)>0 && (i+x)<=dim1 && (j+y)<=dim2 && v(i+x,j+y)==b)  % Searches to the left of the current pixel(i,j) at a row 'a' distance away for any pixel of value b
                    k=0;
                    a=1;
                    i=i+x;
                    j=j+y;               
                    pixel=pixel+1;               
                    data1(pixel)=i;
                    data2(pixel)=j;
                    if(v(i,j)==2)
                        c=c+1;
                    end; 
                    v(i,j)=0;  
                    break;
                end;
            end;
        end;     
        if(k==1)   % If no suitable pixel has still been found , execute the search below
            x=-a;
            for y=-a:a
                if((i+x)>0 && (j+y)>0 && (i+x)<=dim1 && (j+y)<=dim2 && v(i+x,j+y)==b)  % Searches below the current pixel(i,j) at a row 'a' distance away for any pixel of value b
                    k=0;
                    a=1;
                    i=i+x;
                    j=j+y;               
                    pixel=pixel+1;               
                    data1(pixel)=i;
                    data2(pixel)=j;
                    if(v(i,j)==2)
                        c=c+1;
                    end; 
                    v(i,j)=0;  
                    break;
                end;
            end;
        end;
    end;
    if(k==1)             % If no suitable pixel was found for a searching distance of a , it is incremented to a+1
        a=a+1;
    end;
    if(d2==1 && a==1)    % Used for finding the starting point of the line trace of a closed loop 
        h(i,j)=1;
        d2=0;        
    elseif(b==1 && a==2) % Used for finding the end point of the line trace of a closed loop 
        h(i,j)=1;
        d2=1;            % d2 variable is needed so that the preceeding if loop is executed once as soon as 'a' turns to 1
    end;
    if(c==endcount)      % When c reaches endcount b must be made 1 for computational purposes
        b=1;
        c=0;             % c is made 0 so that this if loop gets executed only once
    end;
end; 
h(i,j)=1;                % Makes the last pixel scanned an endpoint in h matrix
imwrite((50*d1+205*h),cmap,'C:\Users\vaio\Desktop\results\Line_trace_ends_detection_result.png','BitDepth',8);
%% VERTICAL AND HORIZONTAL NOISE FILTERING
disp('VERTICAL AND HORIZONTAL NOISE FILTERING PROCESS INITIATED....');
flag=0;          % Used as an input variable by the user to repeat the process
tpow=4;          % Affects the value placed on threshold of a pixel during noise filtering
lpow=2;          % Affects the value placed on length of a line or curve during noise filtering
while(flag==0)
    i=1;
    j=1;
    x=z(data1(1),data2(1)).^tpow;          % Stores the sum of the thresholds.^tpow of the traversed segment
    y=1;                                   % Stores the total length of the traversed segment
    a(1)=data1(1);
    b(1)=data2(1);
    c=10.^(tpow+lpow-3)*input('Enter the value of noise filtering threshold:');
    while (i<totalcount)
        i=i+1;     
        j=j+1;  
        if(abs(data1(i)-data1(i-1))<=1 && abs(data2(i)-data2(i-1))<=1)   
            y=y+1;
            x=x+z(data1(i),data2(i)).^tpow;
        else
            if((x*(y.^(lpow-1)))<c)        % If the segment is having a threshld less than c(noise) , the line's pixel data in a(),b() is overwritten by decreasing j by y
                j=j-y;
            end;
            x=z(data1(i),data2(i)).^tpow;      
            y=1;
        end;
        a(j)=data1(i);                    % a() stores the noiseless pixel row number
        b(j)=data2(i);                    % b() stores the noiseless pixel column number
    end;
    if((x*(y.^(lpow-1)))<c)               % If the last segment is having a threshld less than c(noise) , the line's pixel data in a(),b() is overwritten by decreasing j by y
        j=j-y;
    end;    
    v=zeros(dim1,dim2);
    for i=1:j                             % Reconstructs the noise removed filter for examination by the user 
        v(a(i),b(i))=1;
    end;
    imagesc(v);    
    title('Final Result');
    colormap(gray);
    imwrite(v,'C:\Users\vaio\Desktop\results\Final_result.bmp','bmp');
    flag=input('To repeat image noise filtering,Enter 0(zero):');             % The process can be repeated till a favourable final image is obtained
    close all;
end;
totalcount=j;                            % totalcount's value must be decreased to j due the elimination of noise segments of the trace
%% DRAWING PATH SIMULATION (works best for lower resolution images,640x480 and below)
disp('DRAWING PATH SIMULATION PROCESS INITIATED....');
flag=input('To simulate the final image drawing path,Enter 0(zero):');
while(flag==0) 
    j=input('Enter the number of pixels skipped per frame (increase for greater simulation speeds):');    
    v=zeros(dim1,dim2);    
    for i=1:totalcount
        v(a(i),b(i))=1;       
        if(rem(i,j)==0)
            imagesc(v);     % Displays the v matrix 
            title('Drawing path Simulation');
            colormap(gray); % Colormap for imagesc() function
            getframe;       % Returns a frame from imshow()
        end;
    end;
    flag=input('Simulation over to watch again,Enter 0(zero):');
end;
%% DETERMINING SERVO ANGLE PATH
disp('CALCULATING THE 4 SERVO ANGLES FOR EACH PIXEL ALONG THE DRAWING PATH....');
l1=9.35;l2=9.35;l3=14.4;  % The 3 servo arm lengths
xa=-17;xb=17;             % A4 sheet's x-axis range
ya=3;yb=28.4;             % A4 sheet's y-axis range
invert=1;                 % Set to 1 if s1,s2 and s3 motors are inverted
k=0.8*(l2+l3);            % used for servo1 calculations
x=0;                      % Counts the skipped pixels
y=pi/6;                   % Servo 1's tilt angle about vertical in anticlockwise sense
if(invert==1)
    xa=-xa;               % If motors s1,s2,s3 are inverted then the x-axis must be inverted
    xb=-xb;
end;
for i=1:totalcount
    if(i<=2||(s1(x)~=s1(x-1))||(s2(x)~=s2(x-1))||(s3(x)~=s3(x-1))||(s4(x)~=s4(x-1)))
        x=x+1;
    end;
    x3=xa+(xb-xa)*(b(i)-1)/(dim2-1);
    y3=ya+(yb-ya)*(a(i)-1)/(dim1-1);
    r3=sqrt(x3.^2+y3.^2);   
    o3=atan(y3/x3);                      
    if(x3<0)                             % BASED ON INVERSE KINEMATICS MATHEMATICAL DERIVATIONS
        o3=pi+o3;                        
    end; 
    j=o3+pi/3-y;
    if((r3-l1)<k)
        j=j+(pi/3)*min(1,(1-(r3-l1)/k));
    end;
    s1(x)=round(j*3069/(5*pi));          % Servo1's angle data array (0-1023 values)
    j=s1(x)*(5*pi)/3069-pi/3+y;
    x1=l1*cos(j);
    y1=l1*sin(j);
    r2=sqrt((x3-x1).^2+(y3-y1).^2);
    s2(x)=round((acos((l2.^2+r2.^2-l3.^2)/(2*l2*r2))+acos((l1.^2+r2.^2-r3.^2)/(2*l1*r2))-pi/6)*3069/(5*pi));   % Servo2's angle data array (0-1023 values)      
    s3(x)=round((acos((l2.^2+l3.^2-r2.^2)/(2*l2*l3))-pi/6)*3069/(5*pi));                                       % Servo3's angle data array (0-1023 values)
    if(invert==1)                                                                                              % If servo's s1,s2,s3 are inverted we must subtract the angles from 1023 to get the same movements 
        s1(x)=1023-s1(x);
        s2(x)=1023-s2(x);
        s3(x)=1023-s3(x);  
    end;
    s4(x)=64*floor(s1(x)/256)+16*floor(s2(x)/256)+4*floor(s3(x)/256)+h(a(i),b(i));                             % Stores the 9th and 10th bits of s1(x),s2(x),s3(x) and the lower 2 bits of s4(x) in an encoded form          
    if(x==1||abs(s1(x)-flag)>150)
            s4(x)=s4(x)+2;
    end;
    flag=s1(x);
    s1(x)=rem(s1(x),256);      % Stores the lower byte of s1(x)
    s2(x)=rem(s2(x),256);      % Stores the lower byte of s2(x)
    s3(x)=rem(s3(x),256);      % Stores the lower byte of s3(x)    
end;
totalcount=x;                  % Since many pixel's may be skipped , totalcount's new value is x 
fwrite(ser,[bitand(totalcount,255),bitsrl(uint32(bitand(totalcount,65280)),8),bitsrl(uint32(bitand(totalcount,16711680)),16),100],'uint8');                     % Sends the totalcount to the arduino
%% SERIAL COMMUNICATION WITH ARDUINO
disp('IMAGE DRAWING INITIATED....');
tic;                            % Starts an internal timer that counts in seconds
i=8;                            % Initial value is made 8 to prevent fwrite error
while(i<=totalcount)
    fwrite(ser,[s1(i-7),s2(i-7),s3(i-7),s4(i-7),s1(i-6),s2(i-6),s3(i-6),s4(i-6),s1(i-5),s2(i-5),s3(i-5),s4(i-5),s1(i-4),s2(i-4),s3(i-4),s4(i-4),s1(i-3),s2(i-3),s3(i-3),s4(i-3),s1(i-2),s2(i-2),s3(i-2),s4(i-2),s1(i-1),s2(i-1),s3(i-1),s4(i-1),s1(i),s2(i),s3(i),s4(i)],'uint8');  % Sends the data of 8 pixels simultaneously to the output buffer for serial transmission
    i=i+8;     
    if(rem(i,104)==16)
        clc;                                         % Clears the command window so that the display remains at a constant position
        disp('Robo Artist is drawing your image,please wait...');
        fprintf('The drawing completion percentage:%d o/o\n',uint8(i/totalcount*100));   % Displays the completion percentage,uint8 is unsigned 8 bit integer              
    end;
    if(i~=16)
        while(ser.BytesAvailable==0)                 % wait for arduino to finish it's operations and send's 50      
        end; 
        if(fread(ser,1)~=50)                          
            disp('Serial Error');
        end;
    end;
end; 
pause(.06);                                          % Gives arduino's buffer time to free up upto 28 bytes atleast
for j=(i-7):totalcount                               % Send the last few values to the Arduino
    fwrite(ser,[s1(j),s2(j),s3(j),s4(j)],'uint8');     
end;
i=toc;                                               % Stops the timer and returns the time elapsed in seconds
clc;
fprintf('The total time taken to draw the image:%dminutes,%dseconds\n',uint16(i/60),uint16(rem(i,60)));
fprintf('The number of pixels processed per second:%d\n',uint16(totalcount/i));
pause(6);                                           % Gives the Robotic arm enough time to receive the command to move out of the way
fclose(ser);                                         % Closes the serial communication port with the arduino
disp('IMAGE DRAWING ACCOMPLISHED!!!');
%% END OF PROGRAM