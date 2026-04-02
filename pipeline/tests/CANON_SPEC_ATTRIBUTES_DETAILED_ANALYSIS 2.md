# Canon Mirrorless Camera Specification Attributes - Detailed Analysis

## Overview

This report provides a comprehensive analysis of the **223 unique specification attributes** found across 11 Canon mirrorless cameras from the EOS R series. The analysis categorizes attributes by frequency of occurrence and provides insights into the data structure for parser development.

## 📊 Summary Statistics

- **Total Cameras Analyzed**: 11 (successfully processed)
- **Total Unique Attributes**: 223
- **Analysis Date**: August 2025
- **Data Source**: Canon EOS R series mirrorless cameras

## 🎯 Attribute Frequency Categories

### Core Attributes (Present in 11/11 cameras - 100%)

These attributes appear in **all** successfully processed cameras and form the foundation of Canon's specification structure:

#### **Camera Type & Basic Information**
- **Type** (55 occurrences) - Camera type classification

#### **Sensor & Image Quality**
- **Coverage** (21 occurrences) - Viewfinder coverage percentage
- **Color Filter System** (11 occurrences) - Sensor color filter type
- **Low Pass Filter** (11 occurrences) - Presence/absence of low pass filter
- **Dust Deletion Feature** (11 occurrences) - Dust removal system
- **Image Processor** (10 occurrences) - Image processing engine
- **Total Pixels** (10 occurrences) - Total sensor pixel count

#### **Recording & File Management**
- **Recording Media** (11 occurrences) - Compatible memory card types
- **Recording Format** (11 occurrences) - File recording formats
- **Image Format** (11 occurrences) - Supported image formats
- **File Size** (10 occurrences) - File size specifications
- **File Numbering** (10 occurrences) - File numbering system
- **File Format** (8 occurrences) - File format details

#### **Lens & Mount System**
- **Compatible Lenses** (11 occurrences) - Lens compatibility
- **Lens Mount** (11 occurrences) - Lens mount type

#### **Exposure & Metering**
- **Exposure Compensation** (19 occurrences) - Exposure compensation range
- **Metering Modes** (12 occurrences) - Available metering modes
- **Metering Range** (12 occurrences) - Metering sensitivity range
- **ISO Speed Range** (11 occurrences) - ISO sensitivity range
- **AE Lock** (11 occurrences) - Auto exposure lock
- **Shutter Speeds** (10 occurrences) - Available shutter speeds

#### **White Balance & Color**
- **Aspect Ratio** (11 occurrences) - Image aspect ratios
- **Auto White Balance** (11 occurrences) - Auto white balance settings
- **White Balance Shift** (10 occurrences) - White balance adjustment range
- **Color Space** (9 occurrences) - Color space options

#### **Autofocus System**
- **Number of AF zones available for Automatic Selection** (10 occurrences) - AF zone count
- **Focus Method** (10 occurrences) - Focus method types

#### **Flash System**
- **Flash Exposure Compensation** (11 occurrences) - Flash exposure adjustment
- **E-TTL balance** (10 occurrences) - E-TTL flash balance
- **Continuous flash control** (10 occurrences) - Continuous flash settings

#### **Display & Interface**
- **Monitor Size** (11 occurrences) - LCD monitor dimensions
- **Brightness Control** (11 occurrences) - Display brightness adjustment
- **Interface Languages** (11 occurrences) - Available interface languages
- **Display Format** (11 occurrences) - Display format options
- **Highlight Alert** (11 occurrences) - Highlight warning system
- **Dots** (10 occurrences) - Display resolution in dots
- **Coating** (10 occurrences) - Display coating type
- **Histogram** (10 occurrences) - Histogram display options

#### **File Management & Protection**
- **Protection** (11 occurrences) - File protection system
- **Erase** (11 occurrences) - File deletion options
- **DPOF** (11 occurrences) - Digital Print Order Format
- **My Menu Registration** (11 occurrences) - Custom menu registration

#### **Connectivity & Communication**
- **Transmission Method** (20 occurrences) - Data transmission methods
- **Standards Compliance** (15 occurrences) - Compliance standards
- **USB Terminal** (11 occurrences) - USB connection specifications
- **Communication with a Smartphone** (10 occurrences) - Smartphone connectivity
- **Remote Operation Using EOS Utility** (10 occurrences) - Remote control via EOS Utility
- **Print from Wi-Fi® Printers** (10 occurrences) - Wi-Fi printing capabilities
- **Send Images to a Web Service** (10 occurrences) - Cloud service integration
- **Transition Frequency (Central Frequency)** (10 occurrences) - Wireless frequency details
- **Security** (10 occurrences) - Security features

#### **Power & Battery**
- **Battery** (11 occurrences) - Battery type and specifications
- **Battery Check** (11 occurrences) - Battery status checking
- **Start-up Time** (11 occurrences) - Camera startup duration

#### **Physical Specifications**
- **Dimensions (W x H x D)** (11 occurrences) - Camera dimensions
- **Weight** (11 occurrences) - Camera weight
- **Working Temperature Range** (10 occurrences) - Operating temperature range

### High-Frequency Attributes (Present in 8-10 cameras - 73-91%)

#### **Advanced Features**
- **Viewfinder Information** (8 occurrences) - Viewfinder display information
- **Still Photo IS** (8 occurrences) - Still photo image stabilization
- **Connection Method** (8 occurrences) - Connection method details

#### **Video & Movie Features**
- **Video AF** (7 occurrences) - Video autofocus capabilities
- **Time Code** (7 occurrences) - Time code functionality
- **Time-lapse Movie Setting** (7 occurrences) - Time-lapse movie settings
- **Time-lapse Playback Frame Rate** (7 occurrences) - Time-lapse playback rates

#### **User Interface & Controls**
- **Touch-screen Operation** (7 occurrences) - Touch screen functionality
- **Quick Control Screen** (7 occurrences) - Quick control interface
- **Customizable Dials** (6 occurrences) - Customizable control dials
- **Custom Controls** (5 occurrences) - Custom control options

#### **Advanced Shooting Features**
- **RAW + JPEG / HEIF Simultaneous Recording** (9 occurrences) - Simultaneous RAW/JPEG recording
- **Magnification / Angle of View** (9 occurrences) - Viewfinder magnification
- **Dioptric Adjustment Range** (9 occurrences) - Diopter adjustment range
- **X-sync Speed** (9 occurrences) - Flash sync speed

#### **Connectivity & Output**
- **HDMI Out Terminal** (6 occurrences) - HDMI output specifications
- **Microphone terminal** (6 occurrences) - Microphone input
- **Headphone terminal** (6 occurrences) - Headphone output
- **USB Video Class (UVC)** (6 occurrences) - USB video class support

#### **Printing & Output**
- **Compatible Printers** (9 occurrences) - Printer compatibility
- **Screen Size** (5 occurrences) - Screen size specifications

#### **Advanced Autofocus**
- **Selectable Positions for AF Point** (7 occurrences) - AF point selection options
- **Focusing brightness range (still photo shooting)** (7 occurrences) - AF brightness range for stills
- **Eye Detection** (7 occurrences) - Eye detection autofocus
- **Available AF Areas** (6 occurrences) - Available autofocus areas
- **Available Subject Detection** (6 occurrences) - Subject detection capabilities

#### **Drive & Shooting Modes**
- **Exposure Modes** (7 occurrences) - Available exposure modes
- **Accessory Shoe** (7 occurrences) - Hot shoe specifications
- **Drive Modes and Continuous Shooting Speed** (6 occurrences) - Continuous shooting capabilities

#### **HDR & Advanced Imaging**
- **Still Photo HDR PQ** (6 occurrences) - Still photo HDR PQ
- **Movie HDR PQ** (6 occurrences) - Movie HDR PQ
- **Continuous HDR Shooting (still images)** (6 occurrences) - Continuous HDR shooting
- **HDR Shooting (HDR PQ)** (5 occurrences) - HDR PQ shooting modes

#### **Video Recording**
- **Estimated Recording time, Movie Bit Rate and File Size** (6 occurrences) - Video recording estimates
- **Estimated Recording Time, Continued.** (6 occurrences) - Extended recording time
- **Card Performance Requirements** (6 occurrences) - Memory card requirements
- **Movie Pre-recording (On/Off)** (6 occurrences) - Movie pre-recording feature

#### **Power & Accessories**
- **Optional Battery Grip** (7 occurrences) - Battery grip compatibility
- **Effective pixels** (7 occurrences) - Effective pixel count
- **Working Humidity** (7 occurrences) - Operating humidity range

### Medium-Frequency Attributes (Present in 4-7 cameras - 36-64%)

#### **Advanced Video Features**
- **Clean HDMI Output** (5 occurrences) - Clean HDMI output capability
- **AF Working Range** (5 occurrences) - Autofocus working range
- **Focusing** (5 occurrences) - Focusing system details
- **Maximum Burst** (5 occurrences) - Maximum burst shooting
- **Supporting Standards** (5 occurrences) - Supported standards
- **Video Out Terminal** (4 occurrences) - Video output terminal

#### **Sensor & Image Quality**
- **Sensor Size** (4 occurrences) - Sensor physical dimensions
- **Shutter Lag Time** (4 occurrences) - Shutter lag specifications
- **Effective Pixels** (3 occurrences) - Effective pixel count
- **Pixel Size** (3 occurrences) - Individual pixel size
- **Working Humidity Range** (3 occurrences) - Humidity range specifications

#### **Advanced Shooting Features**
- **Shooting Times** (3 occurrences) - Shooting duration capabilities
- **HDR Mode-Continuous Shooting** (3 occurrences) - Continuous HDR mode
- **Advanced shooting operations** (3 occurrences) - Advanced shooting features
- **AF Methods** (3 occurrences) - Autofocus methods
- **Subject to Detect** (3 occurrences) - Subject detection types

#### **Exposure & Flash**
- **Exposure Control Modes** (3 occurrences) - Exposure control options
- **Compatible E-TTL Speedlites** (3 occurrences) - E-TTL flash compatibility
- **E-TTL II Flash Meterings** (3 occurrences) - E-TTL II flash metering
- **Flash Function Menu** (3 occurrences) - Flash function menu

#### **Advanced Features**
- **Still photo file size / Number of possible shots / Maximum burst for continuous shooting** (3 occurrences) - File size and burst details
- **HDR PQ Shooting** (3 occurrences) - HDR PQ shooting
- **HDR PQ Shooting - Still** (3 occurrences) - Still HDR PQ
- **Canon Log** (3 occurrences) - Canon Log support
- **Custom Functions** (3 occurrences) - Custom function options

#### **Connectivity & Interface**
- **Clean HDMI output** (3 occurrences) - Clean HDMI output
- **Microphone Input Terminal** (3 occurrences) - Microphone input terminal
- **Headphone Terminal** (3 occurrences) - Headphone terminal
- **Customize Buttons** (3 occurrences) - Button customization

### Low-Frequency Attributes (Present in 2-3 cameras - 18-27%)

#### **Specialized Features**
- **Focusing brightness range@999br/> (in movie recording)** (2 occurrences) - Movie AF brightness range
- **Focus mode switch** (2 occurrences) - Focus mode switching
- **HDR PQ Shooting - Movie** (2 occurrences) - Movie HDR PQ
- **Temperature Warning** (2 occurrences) - Temperature warning system
- **Estimated Camera Recovery Time** (2 occurrences) - Camera recovery time
- **Movie Recording Format** (2 occurrences) - Movie recording format
- **Estimated Recording Time and Data** (2 occurrences) - Recording time and data
- **Cloud RAW Image Processing via image.canon (firmware 1.1.0 or higher)** (2 occurrences) - Cloud RAW processing
- **Custom Dials** (2 occurrences) - Custom dials
- **Remote control terminal** (2 occurrences) - Remote control terminal
- **Wireless remote control** (2 occurrences) - Wireless remote control
- **Multi-function shoe** (2 occurrences) - Multi-function shoe
- **Focusing brightness range (in movie recording)** (2 occurrences) - Movie focusing brightness
- **Drive Modes andContinuous Shooting Speed** (2 occurrences) - Continuous shooting speed
- **ExposureCompensation** (2 occurrences) - Exposure compensation
- **Video Recording Size and Frame Rates** (2 occurrences) - Video recording specifications
- **Still Photos** (2 occurrences) - Still photo capabilities
- **Movies** (2 occurrences) - Movie capabilities
- **Pixels** (2 occurrences) - Pixel specifications

### Unique Attributes (Present in 1 camera - 9%)

These attributes appear in only one camera each, representing specialized or model-specific features:

#### **Specialized Stabilization**
- **5-axis Image Stabilization with RF/RF-S, EF/EF-S lenses** (1 occurrence)
- **EOS R7 coordinated In-Body Image Stabilizer Still Shooting performance with RF & RF-S lenses** (1 occurrence)

#### **Advanced Flash Features**
- **Slow Sync@999br/> (P/Av modes)** (1 occurrence)
- **Slow Sync@999br> (P/Av modes)** (1 occurrence)

#### **Specialized Connectivity**
- **USB Cables Compatible with iPhones** (1 occurrence)
- **USB Cables@999br/> Compatible with iPhones** (1 occurrence)
- **Wireless Communications** (1 occurrence)
- **Wireless Connections** (1 occurrence)

#### **Advanced Video Features**
- **Shutter Speed / X-sync Speed** (1 occurrence)
- **Still image resolution** (1 occurrence)
- **Color Space (sill images)** (1 occurrence)
- **Available AF Areas (still images and movies)** (1 occurrence)
- **Available Subject Detection (still images and movies)** (1 occurrence)
- **Video resolution** (1 occurrence)
- **RAW video recording** (1 occurrence)
- **Video compression** (1 occurrence)
- **Video Gamma, Color Space options (in CP/Custom Picture menu)** (1 occurrence)
- **Vertical video recording** (1 occurrence)
- **Audio recording** (1 occurrence)

#### **Advanced Recording Features**
- **Estimated Recording time, Movie Bit Rate and File Size for 4K (Up to 29.97)** (1 occurrence)
- **Estimated Recording time, Movie Bit Rate and File Size for 4K Crop (50.00/59.94 fps)** (1 occurrence)
- **Estimated Recording time, Movie Bit Rate and File Size for Full HD** (1 occurrence)
- **Movie Pre-recording** (1 occurrence)
- **Special frame rates** (1 occurrence)
- **Waveform monitor** (1 occurrence)

#### **Streaming & Communication**
- **Live Switcher Mobile streaming** (1 occurrence)
- **HDMI Streaming** (1 occurrence)
- **Camera Connect streaming** (1 occurrence)

#### **Specialized Controls**
- **Customize Buttons Customizable Dials/Control Ring** (1 occurrence)
- **Drive Modes and Continuous Shooting Speed (all maximum Drive speeds approximate)** (1 occurrence)
- **Still-image HDR shooting** (1 occurrence)

#### **Environmental & Power**
- **Remote Control terminal** (1 occurrence)
- **Temperature Range** (1 occurrence)
- **Humidity Range** (1 occurrence)
- **Video IS** (1 occurrence)
- **Slow Sync (P/Av modes)** (1 occurrence)
- **Recording Times** (1 occurrence)

#### **File Management**
- **Folder** (1 occurrence)
- **Folder Actions** (1 occurrence)
- **News Metadata** (1 occurrence)
- **Still & Movie** (1 occurrence)
- **Maximum shooting Times** (1 occurrence)

#### **Specialized Features**
- **Image Stabilization** (1 occurrence)
- **HDR Mode** (1 occurrence)
- **RAW + JPEG Simultaneous Recording** (1 occurrence)
- **Color Temperature Compensation** (1 occurrence)
- **Magnification** (1 occurrence)
- **AF Points** (1 occurrence)
- **Focusing Modes** (1 occurrence)
- **AF Point Selection** (1 occurrence)
- **AF Assist Beam** (1 occurrence)
- **Exposure Control Systems** (1 occurrence)
- **Flash Metering System** (1 occurrence)
- **FE Lock** (1 occurrence)
- **External Flash Settings** (1 occurrence)
- **Drive Modes** (1 occurrence)
- **Shooting Modes** (1 occurrence)
- **Grid Display** (1 occurrence)
- **Continuous Shooting Time** (1 occurrence)
- **Range** (1 occurrence)
- **Exposure Control** (1 occurrence)
- **Extension System Terminal** (1 occurrence)
- **Power Saving** (1 occurrence)
- **Date/Time Battery** (1 occurrence)

## 🔍 Data Quality Insights

### **Consistency Patterns**
1. **High Consistency**: Core camera specifications (sensor, exposure, connectivity) show consistent structure
2. **Variable Consistency**: Advanced features vary significantly between models
3. **Model-Specific Features**: Unique attributes represent specialized capabilities

### **Attribute Categories**
1. **Technical Specifications**: Sensor, exposure, autofocus, flash
2. **Physical Specifications**: Dimensions, weight, environmental
3. **Connectivity**: USB, Wi-Fi, Bluetooth, HDMI
4. **User Interface**: Display, controls, menus
5. **Advanced Features**: HDR, video, specialized shooting modes
6. **File Management**: Recording, storage, protection

## 🛠️ Parser Development Recommendations

### **Priority Levels**
1. **Core Attributes (100%)**: Essential for all cameras
2. **High-Frequency (73-91%)**: Important for most cameras
3. **Medium-Frequency (36-64%)**: Useful for many cameras
4. **Low-Frequency (18-27%)**: Optional features
5. **Unique (9%)**: Model-specific features

### **Implementation Strategy**
1. **Start with Core**: Implement the 55 core attributes first
2. **Add High-Frequency**: Include the 40+ high-frequency attributes
3. **Extend with Medium**: Add medium-frequency attributes as needed
4. **Handle Unique**: Implement fallback handling for unique attributes

### **Data Normalization**
- Standardize units and measurements
- Normalize attribute names for consistency
- Handle variations in specification formatting
- Implement fallback parsing for non-standard structures

---

*This detailed analysis provides a comprehensive foundation for developing a robust parser for Canon mirrorless camera specifications, ensuring maximum compatibility while handling the full range of features across the EOS R series.*
