import Apodini
import ApodiniOpenAPI


struct TestWebService: WebService {
    var content: some Component {
        Group("users") {
            UsersHandler()
                .pallidor("getAllUsers")
            UserHandler()
                .pallidor("getUser")
        }
        Group("courses") {
            CoursesHandler()
                .pallidor("getAllCourses")
            CourseHandler()
                .pallidor("getCourse")
        }
    }
    
    var configuration: Configuration {
        OpenAPIConfiguration(
            outputFormat: .json,
            outputEndpoint: "oas",
            swaggerUiEndpoint: "oas-ui",
            title: "The great TestWebService - presented by Apodini"
        )
        
        DeltaConfiguration()
            .absolutePath("/Users/eld/Desktop/pallidor_libraries/")
            .strategy(.create)
        
        ExporterConfiguration()
            .exporter(OpenAPIInterfaceExporter.self)
            .exporter(DeltaInterfaceExporter.self)
    }
}

try TestWebService.main()
