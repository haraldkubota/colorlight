#include <node_api.h>
#include "./commons.h"
#include "./sendeth.c"


// Check https://gromnitsky.users.sourceforge.net/js/nodejs/nodejs.pdf for napi documentation

// int socket_open(uint8_t *ifname);
// int socket_close(int);
// unsigned long int get_mac_addr(void);
// int get_ifrindex(void);
//
// // Send data to the socket
// int socket_send(int sockfd, unsigned long int src_mac, unsigned long int dest_mac, unsigned int ether_type, uint8_t *data, int len, unsigned int flags);

napi_value SocketSend(napi_env env, napi_callback_info info) {
    size_t argc = 7;
    napi_value args[7];

    NAPI_CALL(env, napi_get_cb_info(env, info, &argc, args, NULL, NULL));

    NAPI_ASSERT(env, argc == 7, "Wrong number of arguments");

    napi_valuetype valuetype0;
    NAPI_CALL(env, napi_typeof(env, args[0], &valuetype0));

    napi_valuetype valuetype1;
    NAPI_CALL(env, napi_typeof(env, args[1], &valuetype0));

    napi_valuetype valuetype2;
    NAPI_CALL(env, napi_typeof(env, args[2], &valuetype0));

    napi_valuetype valuetype3;
    NAPI_CALL(env, napi_typeof(env, args[3], &valuetype0));

    napi_valuetype valuetype4;
    NAPI_CALL(env, napi_typeof(env, args[4], &valuetype0));

    napi_valuetype valuetype5;
    NAPI_CALL(env, napi_typeof(env, args[5], &valuetype0));

    napi_valuetype valuetype6;
    NAPI_CALL(env, napi_typeof(env, args[6], &valuetype0));

    NAPI_ASSERT(env, valuetype0 == napi_bigint, "Wrong type of arguments 0. Expected number");
    NAPI_ASSERT(env, valuetype1 == napi_bigint, "Wrong type of arguments 1. Expected number");
    NAPI_ASSERT(env, valuetype2 == napi_bigint, "Wrong type of arguments 2. Expected number");
    NAPI_ASSERT(env, valuetype3 == napi_bigint, "Wrong type of arguments 3. Expected number");
    NAPI_ASSERT(env, valuetype4 == napi_object, "Wrong type of arguments 4. Expected array");
    NAPI_ASSERT(env, valuetype5 == napi_bigint, "Wrong type of arguments 5. Expected number");
    NAPI_ASSERT(env, valuetype6 == napi_bigint, "Wrong type of arguments 6. Expected number");

    bool is_typedarray;
    napi_value input_array = args[4];
    NAPI_CALL(env, napi_is_typedarray(env, input_array, &is_typedarray));

    NAPI_ASSERT(env, is_typedarray, "Wrong type of arguments expected buffer to be a typed array");

    napi_typedarray_type array_type;
    size_t byte_offset;
    napi_value input_buffer;
    size_t length;
    NAPI_CALL(env, napi_get_typedarray_info(env, input_array, &array_type, &length, NULL, &input_buffer, &byte_offset));
    NAPI_ASSERT(env, array_type == napi_uint8_array, "Buffer should be uint8");

    void* data;
    size_t byte_length;
    NAPI_CALL(env, napi_get_arraybuffer_info(env, input_buffer, &data, &byte_length));

    int64_t bigValue0;
    uint64_t bigValue1;
    uint64_t bigValue2;
    uint64_t bigValue3;
    uint64_t bigValue5;
    uint64_t bigValue6;

    bool lossless;
    napi_status status;

    status = napi_get_value_bigint_int64(env, args[0], &bigValue0, &lossless);
    NAPI_ASSERT(env, status == napi_ok && lossless , "Could not extract data for argument 0");
    status = napi_get_value_bigint_uint64(env, args[1], &bigValue1, &lossless);
    NAPI_ASSERT(env, status == napi_ok && lossless , "Could not extract data for argument 1");
    status = napi_get_value_bigint_uint64(env, args[2], &bigValue2, &lossless);
    NAPI_ASSERT(env, status == napi_ok && lossless , "Could not extract data for argument 2");
    status = napi_get_value_bigint_uint64(env, args[3], &bigValue3, &lossless);
    NAPI_ASSERT(env, status == napi_ok && lossless , "Could not extract data for argument 3");
    status = napi_get_value_bigint_uint64(env, args[5], &bigValue5, &lossless);
    NAPI_ASSERT(env, status == napi_ok && lossless , "Could not extract data for argument 5");
    status = napi_get_value_bigint_uint64(env, args[6], &bigValue6, &lossless);
    NAPI_ASSERT(env, status == napi_ok && lossless , "Could not extract data for argument 6");


    uint8_t* buffer = (uint8_t *)(data) + byte_offset;

    int result = socket_send((int) bigValue0, (long int)(bigValue1), (unsigned long int)(bigValue2), (unsigned int)(bigValue3), buffer, (int) bigValue5, (unsigned int)(bigValue6));

    napi_value napi_result;
    napi_create_int32(env, result, &napi_result);
    return napi_result;
}

napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor descriptors[] = {
        DECLARE_NAPI_PROPERTY("socketSend", SocketSend),
    };


    NAPI_CALL(env, napi_define_properties(
          env, exports, sizeof(descriptors) / sizeof(*descriptors), descriptors));
    return exports;
}

NAPI_MODULE(NODE_GYP_MODULE_NAME, Init);