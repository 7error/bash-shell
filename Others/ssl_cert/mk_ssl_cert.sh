#!/usr/bin/env bash

# ����������� openssl.cnf: [ alt_names ]
# Ĭ�����ü� openssl.cnf: [ req_distinguished_name ]
# Common Name ������DNS.x�г���
# ��������ļ��޸ĵĵط���
#   1. ����CAǩ֤��飨policy_match.stateOrProvinceName �� policy_match.organizationName��
#   2. ����v3_req��չ��req.req_extensions��
#   3. �޸���֤����ϢĬ��ֵ
#   4. �����˱�������v3_req.subjectAltName��
#   5. ����DNS���ã�[ alt_names ]��

# ע��: CA/serial �ڷ�����֤�����кţ�CA֤��ǩ֤��ÿһ��֤����ű���Ψһ�����������ɾ��CAĿ¼��serial����Ҫ�˹���֤���Ψһ
#      ���ǩ֤ʧ�ܣ��볢���ȼ���CA/serial�ڵ����ݣ�Ȼ���Ƴ�CA�ļ��У���ʹ�� $0 -n [CA/serial����������]

CERT_SVR_NAME=server;
CERT_CLI_NAME=;
CERT_CONF_PATH=openssl.cnf;

CERT_CRYPTO_LEN=2048;
CERT_CA_SERIAL=00;
CERT_CA_TIME=3650;

while getopts "c:f:hl:n:s:t:" OPTION; do
    case $OPTION in
        c)
            CERT_CLI_NAME="OPTARG";
        ;;
        f)
            CERT_CONF_PATH="$OPTARG";
        ;;
        h)
            echo "usage: $0 [options]";
            echo "options:";
            echo "-c=[client cert name]       set client cert name.";
            echo "-f=[configure file]         set configure file(default=$CERT_CONF_PATH).";
            echo "-h                          help message.";
            echo "-l=[cert crypto lengtn]     set cert crypto lengtn(default=$CERT_CRYPTO_LEN).";
            echo "-n=[ca serial]              serial if init ca work dir(default=$CERT_CA_SERIAL).";
            echo "-s=[server cert name]       set server cert name(default=$CERT_SVR_NAME).";
            echo "-t=[ca expire time]         set new ca cert expire time in day(default=$CERT_CA_TIME).";
            exit 0;
        ;;
        l)
            CERT_CRYPTO_LEN=$OPTARG;
        ;;
        n)
            CERT_CA_SERIAL="$OPTARG";
        ;;
        s)
            CERT_SVR_NAME="$OPTARG";
        ;;
        t)
            CERT_CA_TIME=$OPTARG;
        ;;
        ?)  #���в���ʶ��ѡ���ʱ��argΪ?
            echo "unkonw argument detected";
            exit 1;
        ;;
    esac
done

# ��Ҫ��Ŀ¼���ļ�
if [ ! -e CA ]; then
    echo "mkdir CA";
    mkdir -p CA/{certs,crl,newcerts,private};
    touch CA/index.txt;
    echo $CERT_CA_SERIAL > CA/serial;
fi

if [ ! -e ca.key ] || [ ! -e ca.crt ]; then
    echo "generate ca cert";
    openssl req -new -x509 -days $CERT_CA_TIME -keyout ca.key -out ca.crt -config $CERT_CONF_PATH;
fi

# ����֤���ļ�
function mk_cert() {
    CERT_NAME=$1;
    openssl genrsa -out $CERT_NAME.key $CERT_CRYPTO_LEN;
    openssl req -new -key $CERT_NAME.key -out $CERT_NAME.csr -config $CERT_CONF_PATH;
    openssl req -text -noout -in $CERT_NAME.csr;
}

# ������֤�� 
if [ ! -z "$CERT_SVR_NAME" ]; then
    # ������֤��
    mk_cert $CERT_SVR_NAME;
    # ǩ֤
    openssl ca -in $CERT_SVR_NAME.csr -out $CERT_SVR_NAME.crt -cert ca.crt -keyfile ca.key -extensions v3_req -config $CERT_CONF_PATH;
fi

# ���ڿͻ�����֤�ĸ���֤��
if [ ! -z "$CERT_CLI_NAME" ]; then
    mk_cert $CERT_CLI_NAME;
    openssl  pkcs12 -export -inkey $CERT_CLI_NAME.key -in $CERT_CLI_NAME.crt -out $CERT_CLI_NAME.p12;
fi