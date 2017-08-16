$PSVersionTable;

gwmi win32_operatingsystem | select caption, csdversion, version | fl *

