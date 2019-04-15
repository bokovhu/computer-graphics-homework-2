struct Camera {
	vec3 eye;
	vec3 dir;
	vec3 up;
    vec3 right;
};

struct ReflectiveMaterial {
	vec3 n;
    vec3 k;
};
    
struct Material {
    vec3 diffuse;
    vec3 specular;
    vec3 ambient;
    float shininess;
};
	
struct Sphere {
    vec3 center;
    float radius;
    int materialId;
};
    
struct Ray {
    vec3 origin;
    vec3 direction;
};
    
struct Hit {
    vec3 rayOrigin;
    vec3 rayDirection;
    bool didHit;
    vec3 hitPoint;
    vec3 hitNormal;
    int hitMaterialId;
};
    
const Camera camera = Camera (
	vec3 (0.0, 0.0, 0.0),
	vec3 (0.0, 0.0, 1.0),
	vec3 (0.0, 1.0, 0.0),
    vec3 (1.0, 0.0, 0.0)
);

const ReflectiveMaterial gold = ReflectiveMaterial (
    vec3 (0.17, 0.35, 1.5),
    vec3 (3.1, 2.7, 1.9)
);
const ReflectiveMaterial silver = ReflectiveMaterial (
    vec3 (0.14, 0.16, 0.13),
    vec3 (4.1, 2.3, 3.1)
);

const ReflectiveMaterial [] REFLECTIVE_MATERIALS = ReflectiveMaterial [] (gold, silver);

const Material greenMat = Material (
    vec3 (0.01, 0.43, 0.12),
    vec3 (0.4, 0.7, 0.2),
    vec3 (0.5, 0.5, 0.5),
    0.6
);

const Material [] MATERIALS = Material [] (greenMat);

const Sphere sphere = Sphere (
    vec3 (0.0, 0.0, 2.0),
    0.8,
    0
);

vec3 lightDir = normalize (vec3 (-0.5, 0.4, -1.0));
const vec3 lightAmbient = vec3 (0.1, 0.1, 0.1);
const vec3 lightEnergy = vec3 (1.0, 0.8, 1.0);

const float EPSILON = 0.01;

Ray getRay (vec2 pixel) {
    vec3 dir = camera.dir + camera.right * pixel.x + camera.up * pixel.y - camera.eye;
    return Ray (camera.eye, normalize (dir));
}

Hit rayTrace (Ray ray) {
    
    Hit hit = Hit(
        ray.origin,
        ray.direction,
        false,
        vec3 (0.0),
        vec3 (0.0),
        -1
    );
    
    vec3 dist = ray.origin - sphere.center;
    float a = dot (ray.direction, ray.direction);
    float b = dot (dist, ray.direction) * 2.0;
    float c = dot (dist, dist) - sphere.radius * sphere.radius;
    float discr = b * b - 4.0 * a * c;
    if (discr < 0.0) return hit;
    float sqrt_discr = sqrt (discr);
    float t1 = (-b + sqrt_discr) / 2.0 / a;
    float t2 = (-b - sqrt_discr) / 2.0 / a;
    if (t1 <= 0.0) return hit;
    float hitT = (t2 > 0.0) ? t2 : t1;
    hit.didHit = true;
    hit.hitPoint = ray.origin + ray.direction * hitT;
    hit.hitNormal = normalize ((hit.hitPoint - sphere.center));
    hit.hitMaterialId = sphere.materialId;
    return hit;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    
    float aspect = iResolution.x / iResolution.y;
    
    lightDir.x = sin (iTime);
    lightDir.y = cos (iTime);
    lightDir.z = -1.0;
    
    lightDir = normalize (lightDir);
    
    vec2 pixel = vec2 (
        ((fragCoord.x / iResolution.x * aspect) - 0.5) * 2.0,
        ((fragCoord.y / iResolution.y) - 0.5) * 2.0
    );
    vec3 color = vec3 (0.0);
    
    Hit hit = rayTrace (getRay (pixel));
    
    if (hit.didHit) {
        float cosTheta = dot(hit.hitNormal, lightDir);
        Material mat = MATERIALS [hit.hitMaterialId];
        color = lightAmbient * mat.ambient;
        if (cosTheta > 0.0) {
            color += lightEnergy * mat.diffuse * cosTheta;
            vec3 halfway = normalize (-hit.rayDirection + lightDir);
            float cosDelta = dot (hit.hitNormal, halfway);
            if (cosDelta > 0.0) {
                color += lightEnergy * mat.specular * pow(cosDelta, mat.shininess);
            }
        }
    } else {
        color = vec3 (0.0);
    }

    fragColor = vec4(color, 1.0);
}