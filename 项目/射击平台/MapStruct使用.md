## MapStruct  使用手册

### 简介

MapStruct是满足JSR269规范的一个Java注解处理器，用于为Java Bean生成类型安全且高性能的映射。它基于编译阶段生成get/set代码，此实现过程中没有反射，不会造成额外的性能损失。

### 使用-

#### 1.注入方式

- spring注入

```java
@Mapper(componentModel = "spring")
public interface ApiMapper {
}
```

- ClassLoader 加载方式

```java
@Mapper
public interface ApiMapper {
    ApiMapper INSTANCE = Mappers.getMapper(ApiMapper.class);
}
```

建议使用spring注入

####  2.简单使用

**这里定义两个 DO 对象 Person 和 User，其中 user 是 Person 的一个属性 ，一个 DTO 对象 PersonDTO**

```java
@NoArgsConstructor
@AllArgsConstructor
@Data
public class Person {
    private Long id;
    private String name;
    private String email;
    private Date birthday;
    private User user;
}

```

```java
@NoArgsConstructor
@AllArgsConstructor
@Data
public class User {
    private Integer age;
}

```

```java
@NoArgsConstructor
@AllArgsConstructor
@Data
public class PersonDTO {
    private Long id;
    private String name;
    /**
     * 对应 Person.user.age
     */
    private Integer age;
    private String email;
    /**
     * 与 DO 里面的字段名称(birthDay)不一致
     */
    private Date birth;
    /**
     * 对 DO 里面的字段(birthDay)进行拓展,dateFormat 的形式
     */
    private String birthDateFormat;
    /**
     * 对 DO 里面的字段(birthDay)进行拓展,expression 的形式
     */
    private String birthExpressionFormat;

}
```

**定义mapStruct**

```java
@Mapper
public interface PersonConverter {
    PersonConverter INSTANCE = Mappers.getMapper(PersonConverter.class);
    @Mappings({
        @Mapping(source = "birthday", target = "birth"),
        @Mapping(source = "birthday", target = "birthDateFormat", dateFormat = "yyyy-MM-dd HH:mm:ss"),
        @Mapping(target = "birthExpressionFormat", expression = "java(org.apache.commons.lang3.time.DateFormatUtils.format(person.getBirthday(),\"yyyy-MM-dd HH:mm:ss\"))"),
        @Mapping(source = "user.age", target = "age"),
        @Mapping(target = "email", ignore = true)
    })
    PersonDTO entityTodto(Person person);
}
```

若源对象属性与目标对象属性名字一致，会自动映射对应属性,会自动忽略属性为null的值

不一样的属性需要指定，也可以用 format 转成自己想要的类型，也支持表达式的方式。

可以看到像 id、name、email这些名词一致的我并没有指定 source-target，而birthday-birth指定了，转换格式的 birthDateFormat 加了dateFormat 或者 birthExpressionFormat 加了 expression

如果某个属性你不想映射，可以加个 ignore=true

**list<entity>转list<dto>**

如果上面已经定义了entity转dto的方法，可以直接使用list<entity>转list<dto>，不用再作映射

```java
@Mapper
public interface PersonConverter {
    PersonConverter INSTANCE = Mappers.getMapper(PersonConverter.class);
    @Mappings({
        @Mapping(source = "birthday", target = "birth"),
        @Mapping(source = "birthday", target = "birthDateFormat", dateFormat = "yyyy-MM-dd HH:mm:ss"),
        @Mapping(target = "birthExpressionFormat", expression = "java(org.apache.commons.lang3.time.DateFormatUtils.format(person.getBirthday(),\"yyyy-MM-dd HH:mm:ss\"))"),
        @Mapping(source = "user.age", target = "age"),
        @Mapping(target = "email", ignore = true)
    })
    PersonDTO domain2dto(Person person);

    List<PersonDTO> domain2dto(List<Person> people);
}
```

#### 使用

```java
public class PersonConverterTest {
    @Test
    public void test() {
        Person person = new Person(1L,"zhige","zhige.me@gmail.com",new Date(),new User(1));
        PersonDTO personDTO = PersonConverter.INSTANCE.entityTodto(person);
        String format = DateFormatUtils.format(personDTO.getBirth(), "yyyy-MM-dd HH:mm:ss");
        List<Person> people = new ArrayList<>();
        List<PersonDTO> personDTOs = PersonConverter.INSTANCE.entityTodto(people);
    }
}
```

#### 简洁使用

```java
@Mapper
public interface PersonConverter extends BaseMapStruct<PersonDTO, Person>  {
    PersonConverter INSTANCE = Mappers.getMapper(PersonConverter.class);
   
}
```

baseMap中封装的方法

```java
public interface BaseMapStruct<D, E> {
    /**
     * DTO转Entity
     *
     * @param dto /
     * @return /
     */
    E toEntity(D dto);

    /**
     * Entity转DTO
     *
     * @param entity /
     * @return /
     */
    D toDto(E entity);

    /**
     * DTO集合转Entity集合
     *
     * @param dtoList /
     * @return /
     */
    List<E> toEntity(List<D> dtoList);

    /**
     * Entity集合转DTO集合
     *
     * @param entityList /
     * @return /
     */
    List<D> toDto(List<E> entityList);
}
```

如果转换双方属性一致的话可以直接继承baseMapstruct

实例：

```java
public class PersonConverterTest {
    @Test
    public void test() {
        Person person = new Person(1L,"zhige","zhige.me@gmail.com",new Date(),new User(1));
        PersonDTO personDTO = PersonConverter.INSTANCE.toDto(person);
        String format = DateFormatUtils.format(personDTO.getBirth(), "yyyy-MM-dd HH:mm:ss");
        List<Person> people = new ArrayList<>();
        List<PersonDTO> personDTOs = PersonConverter.INSTANCE.toDto(people);
    }
}
```



### 更多使用方法

https://blog.csdn.net/zhige_me/article/details/80699784