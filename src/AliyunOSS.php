<?php

namespace Medz\Component\AliyunOSS;

use Medz\Component\StreamWrapper\AliyunOSS\AliyunOSS as AliyunOssClient;

/**
 * Aliyun OSS StreamWrapper alias encapsulation.
 *
 * 因为原包名称主要针对StreamWrapper的封装
 * 容易让人产生误解，曲解了包的作用。
 * 所以针对原有包做一个别名包。
 *
 * @author Seven Du <lovevipdsw@outlook.com>
 **/
class AliyunOSS extends AliyunOssClient
{
} // END class AliyunOSS extends AliyunOssClient
